
use warnings;
use strict;

use CGI::Fast;
use CGI;
use CGI::Session;

use DBI;
use Digest::MD5 qw(md5 md5_hex md5_base64);

use IO::Handle;
use GnuPG::Interface;

use HTTP::Headers;

use Math::Random::Secure qw(irand);

use URI::Escape;

use DBI;


my $db = DBI->connect("dbi:SQLite:dbname=$ENV{'BASEDIR'}/users.db","","");
$db->do('CREATE TABLE users (id INTEGER PRIMARY KEY, username TEXT, user_token TEXT, keyid TEXT); ');

my $gnupg = GnuPG::Interface->new();
$gnupg->options->hash_init( armor   => 1,
                            homedir => "$ENV{'BASEDIR'}/.gnupg",
                            always_trust => 1, meta_interactive => 0,
                            meta_signing_key_id => '59F1E1F177716644' );


while (my $q = new CGI::Fast) {

	#warn("\npost parameters passed in were: \n");
	#my %params = $q->Vars;
	#foreach my $f (keys (%params)) {
	#	warn(" $f:$params{$f}\n");
	#}

	#warn("\nkeywords passed in were:\n");
	#my @keywords = $q->keywords;
	#foreach my $k (@keywords) {
	#	warn(" $k\n");
	#}

	#warn("\nurl parameters passed in were:\n");
	#my @url_params = $q->url_param('keywords');
	#foreach my $k (@url_params) {
	#	warn(" $k\n");
	#}

	my $gpg_headers = HTTP::Headers->new;
	$gpg_headers->header(X_GPGAuth_Version => '1.3.0');
	$gpg_headers->header(X_GPGAuth_Requested => 'false');
	$gpg_headers->header(X_GPGAuth_Verify_URL => '/index.pl?server_verify');
	$gpg_headers->header(X_GPGAuth_Login_URL => '/index.pl?login');
	$gpg_headers->header(X_GPGAuth_Logout_URL => '/index.pl?logout');
	$gpg_headers->header(X_GPGAuth_Pubkey_URL => '/localhost.pub');

	my $sid = $q->cookie('CGISESSID') || undef;

	my $session = new CGI::Session(undef, $sid, {Directory=>File::Spec->tmpdir});
	$session->expire("+30m");

	if (!$session->param('keyid')) {

		$gpg_headers->header(X_GPGAuth_Progress => 'stage0');
		$gpg_headers->header(X_GPGAuth_Authenticated => 'false');

		my $request_gpgauth = 'false';
		my @url_params = $q->url_param('keywords');
		foreach my $k (@url_params) {
			if ($k eq 'login') {
				$request_gpgauth = 'true';
			} 
			if ($k eq 'protected_content') {
				$request_gpgauth = 'true';
			}
		}

		$gpg_headers->header(X_GPGAuth_Requested => $request_gpgauth);

		if ($q->param('gpg_auth:server_verify_token')) {
			my $ciphertext = $q->param('gpg_auth:server_verify_token');

			# warn("plaintext was: $plaintext");

			#if ($pgp->errstr) {
			#	$gpg_headers->header(X_GPGAuth_Error => 'true');
			#	$gpg_headers->header(X_GPGAuth_Verify_Response => $pgp->errstr);
			#}
			#else {
				# need to set server reponse to plaintext here too?
				#$gpg_headers->header(X_GPGAuth_Verify_Response => $plaintext);
				#}

		}
		elsif ($q->param('gpg_auth:keyid')) {
			if (!$q->param('gpg_auth:user_token_result')) {

				$gpg_headers->header(X_GPGAuth_Progress => 'stage1');
				my $keyid = $q->param('gpg_auth:keyid');

				# add key to local keyring
				my ( $input_1, $output_1, $error_1 ) = ( IO::Handle->new(), IO::Handle->new(), IO::Handle->new() );
				my $handles_recv_keys = GnuPG::Handles->new( stdin => $input_1, stdout => $output_1, stderr => $error_1);

				my $pid_recv_keys = $gnupg->wrap_call
				( commands     => [ qw( --recv-keys ) ],
					command_args => [ $keyid ],
					handles      => $handles_recv_keys,
				);

				waitpid $pid_recv_keys, 0;


				$gnupg->options->recipients( [ $keyid ] );
				$gnupg->options->always_trust( 1 );

				my $nonce = md5_hex(irand());
				my @plaintext = ( 'gpgauthv1.3.0|' . length($nonce) . '|' . $nonce . '|gpgauthv1.3.0' );

				my ( $input, $output, $error ) = ( IO::Handle->new(), IO::Handle->new(), IO::Handle->new() );
				my $handles = GnuPG::Handles->new( stdin => $input, stdout => $output, stderr => $error );

				my $pid = $gnupg->sign_and_encrypt( handles => $handles);

				# Now we write to the input of GnuPG
				print $input @plaintext;
				close $input;

				# now we read the output
				my @ciphertext = <$output>;
				my @error_output = <$error>;   # reading the error

				close $output;
				close $error;

				waitpid $pid, 0;

				if ($error_output[0]) {
					$gpg_headers->header(X_GPGAuth_Error => 'true');
					$gpg_headers->header(X_GPGAuth_User_Auth_Token => $error_output[0]);
				}
				else {
					foreach my $c (@ciphertext) {
						#warn(" $c\n");
						$c = uri_escape($c);
						$c =~ s/%20/\\+/g;
						$c =~ s/\./\\./g;
					}
					$gpg_headers->header(X_GPGAuth_User_Auth_Token => join('', @ciphertext) );
					$db->do("INSERT INTO users VALUES (NULL, NULL, '$plaintext[0]', '$keyid');");
				}
			}
			else {
				$gpg_headers->header(X_GPGAuth_Progress => 'stage2');
				my $keyid = $q->param('gpg_auth:keyid');
				my $token = $q->param('gpg_auth:user_token_result');

				my $query_result = $db->do("SELECT * FROM users WHERE keyid = '$keyid';");

				if ($query_result) {
					$gpg_headers->header(X_GPGAuth_Progress => 'complete');
					$gpg_headers->header(X_GPGAuth_Authenticated => 'true');

					$gpg_headers->header(X_GPGAuth_Refer => '/index.pl');

					my $cookie = $q->cookie(CGISESSID => $session->id);
					$gpg_headers->header(Set_Cookie => $cookie );
					$session->param('keyid', $keyid);

				}
				else {
					$gpg_headers->header(X_GPGAuth_Authenticated => 'false');
				}
			}

		}

	} 
	else {
		$gpg_headers->header(X_GPGAuth_Authenticated => 'true');

		my @url_params = $q->url_param('keywords');
		foreach my $k (@url_params) {
			if ($k eq 'logout') {
				$gpg_headers->header(X_GPGAuth_Authenticated => 'false');
				$gpg_headers->header(X_GPGAuth_Requested => 'false');

				$session->clear(['keyid']);
			} 
		}

	}

	print $gpg_headers->as_string;
	print $q->header;

	print $q->start_html("Perl GPGAuth Backend");
	print $q->h1("Welcome to the Perl gpgauth backend.");
	print $q->end_html;
	$session->flush();

}

db->disconnect();


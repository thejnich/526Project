
use warnings;
use strict;

use CGI::Fast;
use CGI;
use CGI::Session;

use HTTP::Headers;

require Crypt::OpenPGP;
require Crypt::OpenPGP::KeyRing;

use Math::Random::Secure qw(irand);

use Digest::MD5 qw(md5 md5_hex md5_base64);

use URI::Escape;


my $pgp = Crypt::OpenPGP->new( KeyServer => 'pool.sks-keyservers.net', AutoKeyRetrieve => 1, SecRing => 'localhost.sec', PubRing => 'localhost.pub');

if (!$pgp) {
	die 'Cannot allocate pgp object';
}

while (my $q = new CGI::Fast) {

	warn("\npost parameters passed in were: \n");
	my %params = $q->Vars;
	foreach my $f (keys (%params)) {
		warn(" $f:$params{$f}\n");
	}

	warn("\nkeywords passed in were:\n");
	my @keywords = $q->keywords;
	foreach my $k (@keywords) {
		warn(" $k\n");
	}

	warn("\nurl parameters passed in were:\n");
	my @url_params = $q->url_param('keywords');
	foreach my $k (@url_params) {
		warn(" $k\n");
	}

	#my %headers = map { $_ => $q->http($_) } $q->http();
	#my $headerDump = "\nGot the following headers:\n";
	#for my $header ( keys %headers ) {
	#	$headerDump = $headerDump . "$header: $headers{$header}\n";
	#}
	#warn($headerDump);

	my $gpg_headers = HTTP::Headers->new;
	$gpg_headers->header(X_GPGAuth_Version => '1.3.0');
	$gpg_headers->header(X_GPGAuth_Requested => 'false');
	$gpg_headers->header(X_GPGAuth_Verify_URL => '/index.pl?server_verify');
	$gpg_headers->header(X_GPGAuth_Login_URL => '/index.pl?login');
	$gpg_headers->header(X_GPGAuth_Logout_URL => '/index.pl?logout');
	$gpg_headers->header(X_GPGAuth_Pubkey_URL => '/localhost.pub');

	my $sid = $q->cookie('keyid') || $q->param('keyid') || undef;

	CGI::Session->name('keyid');
	my $session = new CGI::Session(undef, $sid, {Directory=>File::Spec->tmpdir});
	$session->expire("+1m");

	if (!$sid) {

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

			eval {
				my $plaintext = $pgp->decrypt(Data => $ciphertext, Passphrase => 'gpg');
				# need to set server reponse to plaintext here too?
				$gpg_headers->header(X_GPGAuth_Verify_Response => $plaintext);
			};
			if ($@) {
				$gpg_headers->header(X_GPGAuth_Error => 'true');
				$gpg_headers->header(X_GPGAuth_Verify_Response => $pgp->errstr);
			}

		}
		elsif ($q->param('gpg_auth:keyid')) {
			if (!$q->param('gpg_auth:user_token_result')) {
				$gpg_headers->header(X_GPGAuth_Progress => 'stage1');
				my $keyid = $q->param('gpg_auth:keyid');

				# make sure this is supposed to be md5_hex and not md5_base64 or something
				my $nonce = md5_hex(irand());

				my $plaintext = 'gpgauthv1.3.0|' . length($nonce) . '|' . $nonce . '|gpgauthv1.3.0';

				eval {
					my $encrypted_data = $pgp->encrypt(Recipients => $keyid, Data => $plaintext);
					my $ciphertext = $pgp->sign(Data => $encrypted_data, Armour => 1, KeyID => '4c643f9e268c4b86', Passphrase => 'gpg');
					warn($pgp->errstr . '\n');
					$gpg_headers->header(X_GPGAuth_User_Auth_Token => quotemeta(uri_escape($ciphertext)) );
				};
				if ($@) {
					$gpg_headers->header(X_GPGAuth_Error => 'true');
					$gpg_headers->header(X_GPGAuth_User_Auth_Token => $pgp->errstr);

				}
			}
		}

	} 
	else {
	}

	print $gpg_headers->as_string;
	print $q->header;

	print $q->start_html("Fast CGI Rocks");
	print $q->h1("Welcome to the Perl gpgauth backend.");
	print $q->end_html;
	$session->flush();

}


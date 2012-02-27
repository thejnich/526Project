
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

use DBI;

my $db = DBI->connect("dbi:SQLite:dbname=$ENV{'BASEDIR'}/users.db","","");
$db->do('CREATE TABLE users (id INTEGER PRIMARY KEY, username TEXT, user_token TEXT, keyid TEXT); ');

#warn("\nenvironment parameters passed in were: \n");
#foreach my $key (sort(keys %ENV)) {
#    warn "$key = $ENV{$key}\n";
#}


my $pgp = Crypt::OpenPGP->new( Compat => 'GnuPG', KeyServer => 'sks.mit.edu', AutoKeyRetrieve => 1,
	SecRing => Crypt::OpenPGP::KeyRing->new(Filename => "$ENV{'BASEDIR'}/.gnupg/secring.gpg"), 
	PubRing => Crypt::OpenPGP::KeyRing->new(Filename => "$ENV{'BASEDIR'}/.gnupg/pubring.gpg"));

if ($pgp->errstr) {
	warn($pgp->errstr);
}

#($pub, $sec) = Crypt::OpenPGP->keygen(Type =>'RSA', Size => '1024', Identity => 'localhost', Passphrase => 'gpg');

if (!$pgp) {
	die 'Cannot allocate pgp object';
}

#sub passphrase_cb {
#	my($cert) = @_;
#	my $prompt;
#	if ($cert) {
#		$prompt = 'gpg',
#		$cert->uid,
#		$cert->key->size,
#		$cert->key->alg,
#		substr($cert->key_id_hex, -8, 8);
#	} else {
#		$prompt = "Enter passphrase: ";
#	}
#	_prompt($prompt, '', 1);
#}

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

			my %hash = $pgp->handle(Data => $ciphertext);
			# warn("plaintext was: $plaintext");

			if ($pgp->errstr) {
				$gpg_headers->header(X_GPGAuth_Error => 'true');
				$gpg_headers->header(X_GPGAuth_Verify_Response => $pgp->errstr);
			}
			else {
				# need to set server reponse to plaintext here too?
				#$gpg_headers->header(X_GPGAuth_Verify_Response => $plaintext);
			}

		}
		elsif ($q->param('gpg_auth:keyid')) {
			if (!$q->param('gpg_auth:user_token_result')) {

				$gpg_headers->header(X_GPGAuth_Progress => 'stage1');
				my $keyid = $q->param('gpg_auth:keyid');

				my $nonce = md5_hex(irand());
				my $plaintext = 'gpgauthv1.3.0|' . length($nonce) . '|' . $nonce . '|gpgauthv1.3.0';

				#my $encrypted = $pgp->encrypt(Recipients => $keyid, Data => $plaintext);
				#my $ciphertext = $pgp->sign(Data => $encrypted, KeyID => 'E64C3D01988E474D', Passphrase => 'gpg', Armour => 1);

				my $ciphertext = $pgp->encrypt(Compat => 'GnuPG', Recipients => $keyid, Data => $plaintext, 
					SignKeyID => '59F1E1F177716644', Armour => 1);

				if ($pgp->errstr) {
					$gpg_headers->header(X_GPGAuth_Error => 'true');
					$gpg_headers->header(X_GPGAuth_User_Auth_Token => $pgp->errstr);
				}
				else {
					warn($ciphertext);
					$ciphertext = uri_escape($ciphertext);
					$ciphertext =~ s/%20/\\+/g;
					$ciphertext =~ s/\./\\./g;
					# warn($ciphertext);
					$gpg_headers->header(X_GPGAuth_User_Auth_Token => $ciphertext );

					$db->do("INSERT INTO users VALUES (NULL, NULL, '$plaintext', '$keyid');");
				}


# -----BEGIN\+PGP\+MESSAGE-----%0AVersion%3A\+GnuPG\+v2\.0\.18\+%28GNU%2FLinux%29%0A%0AhQIMA1KjWsr2reDoAQ%2F%2FWr%2BjqGr1ZfKXxoUlzfTeXNix%2BP2jfBf0Su2R2IuoUvR4%0A16hYmgPAvvezljsI4cKmY2R6C%2FyjjlP8VmPQub%2BkOekEu6%2B%2BnJIuVHyidAWpBPuj%0Aw3HSQ%2FCCLjg4WJA7PRRyrgbqthNf7me9AHcKDPbzVuFt4iRIm5zQQORv%2FyaO%2BXdG%0AqsJXkvIlfFjbyFDlUo8txTEg54aSuceQo5iMnXhoUVd39FLNbhUTVKKdoEm44p4I%0AhNExOEjeB%2F1GnOUZubb6HB3K83kfnIa7XvRsaUZOKrv8oNzjxjKv5mBx6TFq7cI%2B%0A8Rp8r74OK%2Fu%2FZI7ZvjwaBJtPoxjfmSFEkB3seS%2FYFphINcOzdCqaHeOUhM84zH95%0A9uXVBryx5bSuvBd7w%2BiNaMW%2Bld7Urqw0EPc%2Bjj%2Bf49lq%2FMZnKXvE6WliYbuTdMYy%0Akp3yD33pEqbwwCgXALDodobIA8PtXsIOFAV863rhg8%2FmZkAJ6Co84joaMwLR2xON%0AYBcbq13WjmXyJhaGtYT0B0c%2BF25Vu1r6ImL%2BMbNZ3u3%2BiPk%2FlWBBFQKqQoE%2BKMbJ%0A0AoRoCoPBAv8eQBJ1rvdu%2B268NdYk44HlSfS%2FUQH3aYqMkS%2FT5wnACsLlWjTXXLD%0Ackbij8qaw0u0I0HioppYRqvOtQH%2F%2BysoXZLzsL41qbem2Nd0zhR6ayq%2FWK76DKzS%0AwOQBp4n2zpURQ5qWDWiaKnPQhwMKghqpEYsUXDfKF43p%2Ba74KZOD6Blxg0kxrfEF%0AvfWaOlCYeNzzgF3TZw9QS%2BOzHeG8E%2BIP6AfRbYrTxDIPuAzsEQmumP3Y%2F4IAHHdP%0AVyuE40K6djWMimva5B60E6k6pDEdtoPRjoNC3t9Yq%2FRrn9FvVYv44SniCawncqjg%0AN7U0ihga4%2FI7QFbH3OoHo9E%2BJcpGdcHasXvOBnwZDwhe%2F4R15Jo3xgPGmlaZIt86%0ANMHcxrjxwuJZTuteiZPouBEDAx2XM%2BA2dizzIuSotmtoBP8HoMBeHuKx3WINZrnL%0A%2FiPVi3FhpsOUzj20rbuCcD5EhWGItPcjm4UVuoXxrJaWZIipCtRnU9cQrIuoKBEm%0AVZp2LmyEtSKEFIfadASlAQRZo1HoJNQnC18duUQiIv%2BiL%2BfIsIuNl15w4YKgvPOW%0AR%2Fof7%2Fqk89nvKcY0bwts%2FjvBu4aiO%2B8duoEXy3BQfmemybqz85BYuLZyp8jzjeXj%0AdVzOrqfnt%2Biok5J6Kpg720mJOWDItDHrt2c1c70Tf1qwDcUJ59o%3D%0A%3DLKGp%0A-----END\+PGP\+MESSAGE-----%0A
# -----BEGIN\+PGP\+MESSAGE-----%0AVersion%3A\+Crypt%3A%3AOpenPGP\+1\.06%0A%0AhQIMAwnq6Uy%2FfavKAQ%2F%2BIPEs5gpHxItEcO16aGB8dodg9Xadxh60Z8FXOe8cInfh%0Aa3OrKkwiKVCCAtgavjHrYKJUfP%2BpOH442zeulfKZYk83lVhoiOgxKBB2T8zA%2BeTF%0A4iLHqZejjldFmwPZLNVuQKQOkqs2XP8o1ja3brKmVr7jCTdxb6YxKrscNpNAEDo5%0AKvWUlBlhw8g36kQSMFXDOtENRzBkiCH8N5IKv%2BMemz8SnXQUog%2FFYhMkDxqGMuNe%0A59JQ1CuKMNLM33acJp9Zh%2FDJ8Mewy0fJM9bzQVYbDO%2BVCR3Huev1Zs5CMtWCJ7gF%0AUjn0B2L3Efar%2Fvx04JzcVGaeqQvZ0fVnpbCh6ibVmFej80aP%2BX38GXX57F19ZU2K%0AbAj47y9gq0A8C0QbfBSxzOB3OP6cvug6t2IgPJug%2Fp743JH3Xz9gTS6IOaiUEksr%0AUhMlRWxNYjP91OhFuH5jyq1VBURCcOQvm3EEOp0Gp4j4H8Gp2qZsDby0y2CNVC2Z%0AE23bMQpfLwGVTyNS13nA3L7L2YWph8pqGUjSQ6xNeDW7MnIT13DXzaYc7ApUQ9Cg%0AYsZdlR9sJQOPfcQfCewOwvE4ir%2B6ndM6yTLHbzh9%2FYAUZAHdxVGJF0VYObDlrCHL%0Af%2Fn%2F96NspIpV8znbvthFcW4LKUbQQtKsJWWl%2F4EcuYKU39q0K3s7UJUQzvKqYHSk%0AcU6BSvIt8Qq9KPsbY6U%2BNOWrV0eflyVFDaJYt2BZQfr8d2kOdJQVT4mPg6EuPdN0%0AIIoUZvwmKEHq7ieGFGrLZFhI8ZO5LxQxi1fe1Bsb7rikr2bKS6mZOwCCiFMROaS8%0A3WFs8hipWEDHBeXr22oS3P90%0A%3DhMth%0A-----END\+PGP\+MESSAGE-----%0A
			}
			else {
				$gpg_headers->header(X_GPGAuth_Programm => 'stage2');
				my $keyid = $q->param('gpg_auth:keyid');
				my $token = $q->param('gpg_auth:user_token_result');

				my $query_result = $db->do("SELECT * FROM users WHERE (keyid, '$keyid');");

				if ($query_result) {
					$gpg_headers->header(X_GPGAuth_Progress => 'complete');
					$gpg_headers->header(X_GPGAuth_Authenticated => 'true');

					$gpg_headers->header(X_GPGAuth_Refer => '/index.php');

					$session->param("keyid", $keyid);
				}
				else {
					$gpg_headers->header(X_GPGAuth_Authenticated => 'false');
				}
			}

		}

	} 
	else {
		$gpg_headers->header(X_GPGAuth_Authenticated => 'true');

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


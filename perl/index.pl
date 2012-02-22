
use warnings;
#use strict;

use CGI::Fast;
use CGI;
use CGI::Session;

use HTTP::Headers;

require Crypt::OpenPGP;
require Crypt::OpenPGP::KeyRing;

use URI::Escape;


my $pgp = Crypt::OpenPGP->new( KeyServer => 'pool.sks-keyservers.net', AutoKeyRetrieve => 1, SecRing => 'localhost.sec', PubRing => 'localhost.pub');

if (!$pgp) {
	die 'Cannot allocate pgp object';
}

$COUNTER = 0;

while ($q = new CGI::Fast) {

	print "X-GPGAuth-Version: 1.3.0\r\n";
	#print "X-GPGAuth-Requested: false\r\n";
	print "X-GPGAuth-Verify-URL: /index.pl?server_verify\r\n";
	print "X-GPGAuth-Login-URL: /index.pl?login\r\n";
	print "X-GPGAuth-Logout-URL: /index.pl?logout\r\n";
	print "X-GPGAuth-Pubkey-URL: /localhost.pub\r\n";

	$sid = $q->cookie('key_id') || $q->param('key_id') || undef;
	$session = new CGI::Session(undef, $sid, {Directory=>File::Spec->tmpdir});

	if (!$sid) {
		$session->name('key_id');
		$session->expire("60");

		print "X-GPGAuth-Progress: stage0\r\n";
		print "X-GPGAuth-Authenticated: false\r\n";

		$request_gpgauth = 'false';
		if ($q->param('protected_content') || $q->param('login')) {
			$request_gpgauth = 'true';
		}

		print "X-GPGAuth-Requested: $request_gpgauth\r\n";

		if ($q->param('gpg_auth:server_verify_token')) {
			$ciphertext = $q->param('gpg_auth:server_verify_token');

			eval {
				$plaintext = $pgp->decrypt(Data => $ciphertext, Passphrase => 'gpg') or die "Decyption Failed: " . $pgp->errstr;
			};
			if ($@) {
				print $@->getErrorMessage();  
			}
		}


	 } 
	 else {

	 }

	print $q->header;

	print $q->start_html("Fast CGI Rocks");
	print $q->h1("Fast CGI Rocks"),
		"Invocation number ",b($COUNTER++),
		" PID ",b($$),".";

	print $q->end_html;
	$session->flush();

}


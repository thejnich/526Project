
use warnings;
use strict;

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

	$q->header(-XASD => 'asdf');
	print "X-GPGAuth-Version: 1.3.0\r\n";
	#print "X-GPGAuth-Requested: false\r\n";
	print "X-GPGAuth-Verify-URL: /index.pl?server_verify\r\n";
	print "X-GPGAuth-Login-URL: /index.pl?login\r\n";
	print "X-GPGAuth-Logout-URL: /index.pl?logout\r\n";
	print "X-GPGAuth-Pubkey-URL: /localhost.pub\r\n";

	my $sid = $q->cookie('keyid') || $q->param('keyid') || undef;

	CGI::Session->name('keyid');
	my $session = new CGI::Session(undef, $sid, {Directory=>File::Spec->tmpdir});
	$session->expire("+1m");

	if (!$sid) {

		print "X-GPGAuth-Progress: stage0\r\n";
		print "X-GPGAuth-Authenticated: false\r\n";

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
		
		print "X-GPGAuth-Requested: $request_gpgauth\r\n";

		if ($q->param('gpg_auth:server_verify_token')) {
			my $ciphertext = $q->param('gpg_auth:server_verify_token');
			my $plaintext = $pgp->decrypt(Data => $ciphertext, Passphrase => 'gpg') 
				or die "Decyption Failed: " . $pgp->errstr;
		}


	 } 
	 else {

	 }

	print $q->header;

	print $q->start_html("Fast CGI Rocks");
	print $q->end_html;
	$session->flush();

}


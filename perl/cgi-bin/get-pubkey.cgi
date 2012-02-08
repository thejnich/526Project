#!/usr/bin/perl
use warnings;
#use strict;

require HTTP::Request;
require LWP::UserAgent;
#require Crypt::OpenSSL::Random;
#require Crypt::OpenSSL::RSA;
require Crypt::OpenPGP;
require Crypt::OpenPGP::KeyRing;

use URI::Escape;


#Crypt::OpenSSL::RSA->import_random_seed();


# this gets all the form data that was POST'ed
read(STDIN, $line, $ENV{'CONTENT_LENGTH'});
@values = split(/&/, $line);

print "Content-type:text/html\r\n\r\n";
print '<html>';
print '<head>';
print '</head>';
print '<body>';

print "<h2>These were the values sent</h2>\n";

# this parses all the form data!
foreach $i (@values) {
	($varname, $data) = split(/=/, $i);
	print "The variable is $varname, the value is $data<p>";
	$searched_name = $data;
}

# http://keyserver.ubuntu.com:11371/pks/lookup?search=milz&op=get

#$request = HTTP::Request->new(GET => 'http://pool.sks-keyservers.net:11371/pks/lookup?search='.$searched_name.'&op=get');
#$ua = LWP::UserAgent->new;
#$response = $ua->request($request);

# print $response->decoded_content; 

#$public_key = $response->decoded_content;

#$public_key =~ /<pre>([\s\S]+?)<\/pre>/;
#$bare_public_key = $1;
#print $bare_public_key;

#$pgp_keyring = Crypt::OpenPGP::KeyRing->new($bare_public_key);
$bare_name = uri_unescape($searched_name);
my $pgp = Crypt::OpenPGP->new( KeyServer => 'pool.sks-keyservers.net', AutoKeyRetrieve => 1 );
my $ciphertext = $pgp->encrypt( Armoured => 1, Recipients => $bare_name, Data => 'asdfaf' );

print $ciphertext;

#$rsa_pub = Crypt::OpenSSL::RSA->new_public_key($bare_public_key);


#print $rsa->get_public_key_string();

#$rsa_pub = $response->decoded_content;
#$rsa_pub->use_sslv23_padding(); # use_pkcs1_oaep_padding is the default

#$plaintext = 
#$ciphertext = $rsa->encrypt($plaintext);


print '</body>';
print '</html>';

1;

#!/usr/bin/perl

require HTTP::Request;
require LWP::UserAgent;
require Crypt::OpenSSL::Random;
require Crypt::OpenSSL::RSA;

# Crypt::OpenSSL::RSA->import_random_seed();


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

$request = HTTP::Request->new(GET => 'http://keyserver.ubuntu.com:11371/pks/lookup?search='.$searched_name.'&op=get');
$ua = LWP::UserAgent->new;
$response = $ua->request($request);

print $response->decoded_content; 

# $rsa_pub = 
# $rsa_pub->use_sslv23_padding(); # use_pkcs1_oaep_padding is the default

# $ciphertext = $rsa->encrypt($plaintext);


print '</body>';
print '</html>';

1;

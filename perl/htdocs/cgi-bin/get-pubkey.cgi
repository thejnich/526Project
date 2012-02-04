#!/usr/bin/perl

require HTTP::Request;
require LWP::UserAgent;

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
}

# http://pgp.mit.edu:11371/pks/lookup?search=torvalds%40linux-foundation.org&op=index&exact=on

$request = HTTP::Request->new(GET => 'http://pgp.mit.edu:11371/pks/lookup?search=torvalds%40linux-foundation.org&op=index&exact=on');
$ua = LWP::UserAgent->new;
$response = $ua->request($request);

print $response->decoded_content; 

print '</body>';
print '</html>';

1;

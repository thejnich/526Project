#!/usr/bin/env perl

use warnings;
use strict;

require Crypt::OpenPGP;
require Crypt::OpenPGP::Armour;

my $pgp  = Crypt::OpenPGP->new(Compat => 'GnuPG');
my($pub, $sec) = $pgp->keygen(Type =>'RSA', Size => '2048', Identity => 'Perl Backend <localhost>', Passphrase => 'gpg');

print 'secret key id: ' . $sec->signing_key->key_id_hex;

open FILE, ">localhost.sec" or die $!;
print FILE $sec->save;
close FILE;

open FILE, ">localhost.pub" or die $!;
#print FILE Crypt::OpenPGP::Armour->armour(Data => $pub->save, Object => "PUBLIC KEY BLOCK");
print FILE $pub->save_armoured;
close FILE;


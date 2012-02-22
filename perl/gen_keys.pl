#!/usr/bin/perl

use warnings;
#use strict;

require Crypt::OpenPGP;
require Crypt::OpenPGP::Armour;


($pub, $sec) = Crypt::OpenPGP->keygen(Type =>'RSA', Size => '2048', Identity => 'localhost', Passphrase => 'gpg');

open FILE, ">localhost.sec" or die $!;
print FILE $sec->save;
close FILE;

open FILE, ">localhost.pub" or die $!;
#print FILE Crypt::OpenPGP::Armour->armour(Data => $pub->save, Object => "PUBLIC KEY BLOCK");
print FILE $pub->save_armoured;
close FILE;


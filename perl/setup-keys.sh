#!/bin/sh
#
# helper script to generate some new keys and set everything up
# run this script in the directory where you want to store your secrets

mkdir -p -m 700 .gnupg
gpg --gen-key --homedir .gnupg
gpg --homedir .gnupg --output localhost.pub --armour --export


#!/bin/sh
#
# helper script to generate some new keys and set everything up
# run this script in the directory where you want to store your secrets

printf "WARNING\n"
printf "use your domain name for the email address of the keys.\n"
printf "WARNING\n\n"

rm -rf .gnupg/pubring.gpg* .gnupg/secring.gpg .gnupg/trustdb.gpg server.pub
mkdir -p .gnupg
chmod 700 .gnupg
gpg --gen-key --homedir .gnupg
gpg --homedir .gnupg --output server.pub --armour --export


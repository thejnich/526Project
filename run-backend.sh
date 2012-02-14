#!/bin/bash


if [ $# -ne 1 ]; then
	echo "Must specify one backend to run, one of"
	echo "  ${0} <--perl|--ruby|--php>"
	exit
fi

if [ "$1" == "--perl" ]; then
	echo -ne "\e[1;36m"
	echo "launching lighttpd perl backend"
	echo -ne "\e[0m"
	echo -e " -> the server can be accessed via 127.0.0.1:8080 in a web browser\n"
	lighttpd -f conf/perl/lighttpd.conf -D
elif [ "$1" == "--php" ]; then
	echo -ne "\e[1;35m"
	echo "launching lighttpd php backend"
	echo -ne "\e[0m"
	echo -e " -> the server can be accessed via 127.0.0.1:8080 in a web browser\n"
	lighttpd -f conf/php/lighttpd.conf -D
elif [ "$1" == "--ruby" ]; then
	echo -ne "\e[1;31m"
	echo "launching ruby on rails backend"
	echo -ne "\e[0m"
	pushd ruby
	rails server
	popd
else
	echo "Must specify one backend to run, one of"
	echo "  ${0} <--perl|--ruby|--php>"
	exit
fi

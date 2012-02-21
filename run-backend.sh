#!/bin/bash

error_msg () {
	echo "Must specify one backend to run, one of"

	echo -ne "$ ${0} <"
	echo -ne "\e[1;36m--perl\e[0m|"
	echo -ne "\e[1;31m--ruby\e[0m|"
	echo -ne "\e[1;35m--php\e[0m"
	echo ">"

	exit
}

if [ $# -ne 1 ]; then
	error_msg
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
	error_msg
fi



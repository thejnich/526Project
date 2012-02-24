#!/bin/bash

error_msg () {
	printf "Must specify one backend to run, one of\n"

	printf "$ ${0} <"
	printf "\e[1;36m--perl\e[0m|"
	printf "\e[1;31m--ruby\e[0m|"
	printf "\e[1;35m--php\e[0m|"
	printf "\e[1;33m--python\e[0m"
	printf ">\n"

	exit
}

if [ $# -ne 1 ]; then
	error_msg
fi

if [ "$1" == "--perl" ]; then
	printf "\e[1;36m"
	printf "launching lighttpd perl backend\n"
	printf "\e[0m"
	printf " -> the server can be accessed via localhost:8080 in a web browser\n\n"
	lighttpd -f conf/perl/lighttpd.conf -D
elif [ "$1" == "--php" ]; then
	printf "\e[1;35m"
	printf "launching lighttpd php backend\n"
	printf "\e[0m"
	printf " -> the server can be accessed via localhost:8080 in a web browser\n\n"
	lighttpd -f conf/php/lighttpd.conf -D
elif [ "$1" == "--ruby" ]; then
	printf "\e[1;31m"
	printf "launching ruby on rails backend\n"
	printf "\e[0m"
	pushd ruby
	rails server
	popd
elif [ "$1" == "--python" ]; then
	printf "\e[1;33m"
	printf "launching python backend\n"
	printf "\e[0m"
	printf " -> the server can be accessed via localhost:8080 in a web browser\n\n"
	lighttpd -f conf/python/lighttpd.conf -D

else
	error_msg
fi



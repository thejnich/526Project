#!/bin/sh

if [ $# -ne 1 ]; then
	echo "Must specify one backend to run, one of"
	echo "  ${0} <--perl|--ruby>"
	exit
fi

if [ "$1" == "--perl" ]; then
	echo -ne "\e[1;36m"
	echo "launching lighttpd perl backend"
	echo -ne "\e[0m"
	echo "the server can be accessed via 127.0.0.1:8080 in a web browser"
	lighttpd -f perl/conf/lighttpd.conf -D
fi

if [ "$1" == "--ruby" ]; then
	echo -ne "\e[1;31m"
	echo "launching ruby on rails backend"
	echo -ne "\e[0m"
	pushd ruby
	rails server
	popd
fi

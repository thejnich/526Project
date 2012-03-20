#!/usr/bin/env python
# -*- coding: UTF-8 -*-

from cgi import  escape
import sys, os, Cookie 
from flup.server.fcgi import WSGIServer
from urlparse import parse_qs

#import GnuPGInterface

sessid = 'PYSESSID'

page = ''' 
<html>
<head><title>Python GPGWebAuth</title></head>
<body>
%s
</body>
</html>
'''


def showEnviron(environ):
	env = []
	env.append('<table>')
	env.extend(['<tr><th>%s</th><td>%s</td></tr>' % (key, value) for key, value in sorted(environ.items())])
	env.append('</table>')
	return env

def myapp(environ, start_response):

	status = '200 ok'

	# create dictionary for response headers
	response_headers = dict( [('Content-Type', 'text/html'),
	('Content-Length', '0'),
	('X-GPGAuth-Version', '1.3.0'),
	('X-GPGAuth-Requested', 'false'),
	('X-GPGAuth-Verify-URL', '/index.py?server_verify'),
	('X-GPGAuth-Login-URL', '/index.py?login'),
	('X-GPGAuth-Logout-URL', '/index.py?logout'),
	('X-GPGAuth-Pubkey-URL', '/server.pub'),
	('X-GPGAuth-Progress', 'stage0'),
	('X-GPGAuth-Authenticated', 'false')] )

	# body of response is a list of strings
	response_body = ['<h1>Hello, and welcome to movie phone</h1>']

	# get dictionary of query strings
	url_params = parse_qs(environ['QUERY_STRING'], True)
	


	# use cookie to manage session, not functional
	if not ('HTTP_COOKIE' in environ and sessid in environ['HTTP_COOKIE']):
		# new session
		response_body.append('new session')

		if ('login' in url_params) or ('protected_content' in url_params):
			response_headers['X-GPGAuth-Requested'] = 'true'
		
		try:
			request_body_size = int(environ.get('CONTENT_LENGTH', 0))
		except (ValueError):
				request_body_size = 0

		request_body = environ['wsgi.input'].read(request_body_size)
		post = parse_qs(request_body)

		print >> sys.stderr, 'post:\n%s' % post
		
		if 'gpg_auth:server_verify_token' in post:
			# client has requested server to verify itself
			cipherText = post['gpg_auth:server_verify_token']

			print >> sys.stderr, 'verifying server...'	
			# now decrypt and send response back to client
	

		#cookie = Cookie.SimpleCookie()
		#cookie[sessid] = '1234'
		#response_headers['Set-Cookie'] = cookie.output(header='')	
	else:
		# The user already has a registered session
		response_body.append('found session idi, THIS SHOULD NOT HAPPEN YET')


	response_body.extend(showEnviron(environ))
	# create one string
	response_body = '\n'.join(response_body)
	
	# insert into body tag of page
	ret = page % response_body

	# set content length
	response_headers['Content-Length'] = str(len(ret))

	# convert into a list of tuples, as expected by start_response
	response_headers = [(k,v) for k,v in response_headers.items()]
	
	start_response(status, response_headers)

	return [ret]



WSGIServer(myapp).run()


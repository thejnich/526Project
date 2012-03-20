#!/usr/bin/env python
# -*- coding: UTF-8 -*-

from cgi import escape
import sys, os, Cookie, time
from flup.server.fcgi import WSGIServer

#import GnuPGInterface

def showEnviron(response_body, environ):
	response_body.append('<table>')
	response_body.extend(['<tr><th>%s</th><td>%s</td></tr>' % (key, value) for key, value in sorted(environ.items())])
	response_body.append('</table>')


def app(environ, start_response):
	response_body = ['<h1>You are not logged in</h1>']
	response_headers = [('Content-Type', 'text/html')]

	if 'HTTP_COOKIE' in environ and 'keyid' in environ['HTTP_COOKIE']:
		response_body.append('found keyid')
	else:
		response_body.append('no keyid')
		cookie = Cookie.SimpleCookie()
		cookie['keyid'] = '1234'
		response_headers.extend([('Set-Cookie', cookie.output(header=''))])	

	response_body = '\n'.join(response_body)
	status = '200 ok'
	response_headers.extend([
	('Content-Length', str(len(response_body))),
	('X-GPGAuth-Version', '1.3.0'),
	('X-GPGAuth-Requested', 'false'),
	('X-GPGAuth-Verify_URL', '/index.py?server_verify'),
	('X-GPGAuth-Login_URL', '/index.py?login'),
	('X-GPGAuth-Logout_URL', '/index.py?logout'),
	('X-GPGAuth-Pubkey_URL', '/server.pub'),
	('X-GPGAuth-Progress', 'stage0'),
	('X-GPGAuth-Authenticated', 'false')])

	start_response(status, response_headers)


	return [response_body]

WSGIServer(app).run()


#!/usr/bin/env python
# -*- coding: UTF-8 -*-

from cgi import escape
import sys, os
from flup.server.fcgi import WSGIServer

#import GnuPGInterface

def app(environ, start_response):
	status = '200 ok'
	response_headers = [('Content-Type', 'text/html'), 
	('X-GPGAuth-Version', '1.3.0'),
	('X-GPGAuth-Requested', 'false'),
	('X-GPGAuth-Verify_URL', '/index.py?server_verify'),
	('X-GPGAuth-Login_URL', '/index.py?login'),
	('X-GPGAuth-Logout_URL', '/index.py?logout'),
	('X-GPGAuth-Pubkey_URL', '/server.pub'),
	('X-GPGAuth-Progress', 'stage0'),
	('X-GPGAuth-Authenticated', 'false')]

	start_response(status, response_headers)

	yield '<h1>You are not logged in</h1>'
	yield '<table>'
	for k, v in sorted(environ.items()):
		yield '<tr><th>%s</th><td>%s</td></tr>' % (escape(k), escape(v))
	yield '</table>'

WSGIServer(app).run()


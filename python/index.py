#!/usr/bin/env python
# -*- coding: UTF-8 -*-

from cgi import  escape
import sys, os, Cookie, urllib, re, uuid, md5, sqlite3 
from flup.server.fcgi import WSGIServer
from urlparse import parse_qs

import gnupg 

sessid = 'PYSESSID'

page = ''' 
<html>
<head><title>Python GPGWebAuth</title></head>
<body>
%s
</body>
</html>
'''
def debugPrint(msg):
	print >> sys.stderr, msg

def showEnviron(environ):
	env = []
	env.append('<table>')
	env.extend(['<tr><th>%s</th><td>%s</td></tr>' % (key, value) for key, value in sorted(environ.items())])
	env.append('</table>')
	return env

def getFingerprint(gpg, keyid):
	keys = gpg.list_keys()
	for key in keys:
		if key['keyid'] == keyid:
			return key['fingerprint']
	return ''


def myapp(environ, start_response):
	con = sqlite3.connect(os.environ['PWD']+'/python/users.db')
	con.isolation_level = None
	cur = con.cursor()
	cur.execute('CREATE TABLE if not exists users (user_token TEXT, keyid TEXT UNIQUE); ')

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
	
	gpg = gnupg.GPG(gnupghome=os.environ['PWD']+'/python/.gnupg')

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

		debugPrint('post:\n%s' % post)
		
		if 'gpg_auth:server_verify_token' in post:
			# client has requested server to verify itself
			cipherText = post['gpg_auth:server_verify_token'][0]

			debugPrint('verifying server...\nCipherText:\n'+cipherText)

			# now decrypt and send response back to client
			plainText = gpg.decrypt(cipherText)
			if plainText == '':
				debugPrint('challenge from client not decrypted. Check that keyring has right key')
			else:
				debugPrint('plaintext:: ' + str(plainText))
				response_headers['X-GPGAuth-Verify-Response'] = str(plainText)
		elif 'gpg_auth:keyid' in post:
			if not ('gpg_auth:user_token_result' in post):
				response_headers['X-GPGAuth-Progress'] = 'stage1'
				
				keyid = post['gpg_auth:keyid'][0]
				gpg.recv_keys('keyserver.ubuntu.com', keyid)
				debugPrint('keyid: %s' % keyid)

				# generate nonce and encrypt send to user........
				# for now hard code

				nonce = md5.new(uuid.uuid4().hex).hexdigest()
				plainText = 'gpgauthv1.3.0|'+str(len(nonce))+'|'+nonce+'|gpgauthv1.3.0'
				debugPrint('Plaintext to encrtyp: %s' % plainText)


				recipient_fingerprint = getFingerprint(gpg, keyid)
				if recipient_fingerprint == '':
					debugPrint('error finding fingerprint')
					response_headers['X-GPGAuth-Error'] = 'true'
					response_headers['X-GPGAuth-User-Auth-Token'] = 'error finding fingerprint'
				else:
					cipherText = str(gpg.encrypt(plainText, recipient_fingerprint, always_trust=True,
					sign='1CB6F42F2FBCB423600C3E156EEA5FD5027EB2A9'))
					debugPrint('Encrypted data: %s' % cipherText)

					# encode cipherText
					cipherText = urllib.quote_plus(cipherText)
					cipherText = re.sub('\.', '\\.', cipherText)
					cipherText = re.sub('\+', '\\+', cipherText)
					debugPrint('escaped cipher: %s' % cipherText)

					response_headers['X-GPGAuth-User-Auth-Token'] = cipherText	

					# insert keyid,plaintext token into db so it can be verified upon client response
					t = (plainText,keyid)
					cur.execute("REPLACE INTO users VALUES (?,?)", t)
					debugPrint('inserted/updated db')

			else:
				# we have both user key-id and decrypted version of token we prev provided client
				# so either the client has verified identity of server, or selected proceed anyway
				response_headers['X-GPGAuth-Progress'] = 'stage2'
				keyid = post['gpg_auth:keyid'][0]
				token = post['gpg_auth:user_token_result'][0]
				if keyid == '' or token == '':
					errmsg = 'stage 2 error, keyid or token is empty'
					debugPrint(errmsg)
					response_headers['X-GPGAuth-Error'] = 'true'
					response_headers['X-GPGAuth-User-Auth-Token'] = errmsg
				else:
					debugPrint('token: %s' % token)
					t = (token,keyid)
					cur.execute("SELECT * FROM users WHERE user_token = ? AND keyid = ?", t)
					result = cur.fetchall()
					if len(result) != 0:
						response_headers['X-GPGAuth-Progress'] = 'complete'
						response_headers['X-GPGAuth-Authenticated'] = 'true'
						#cookie = Cookie.SimpleCookie()
						#cookie[sessid] = '1234'
						#response_headers['Set-Cookie'] = cookie.output(header='')	


	else: # of very first if, this code is BRUTAL
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
	

	con.close()
	start_response(status, response_headers)

	return [ret]



WSGIServer(myapp).run()


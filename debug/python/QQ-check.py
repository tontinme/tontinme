#!/usr/bin/env python
#coding=utf-8
import datetime
import urllib2
try:
	verify = raw_input("Please input your qq number:")
except KeyboardInterrupt:
	pass
def check_qq(verify):
	if verify.isdigit():
		checkurl = 'http://wpa.qq.com/pa?p=1:' + verify + ':1'
		c = urllib2.urlopen(checkurl)
		length = c.headers.get("content-length")
		print c.headers
		print length
		c.close()
		print datetime.datetime.now()
		if length == '2329':
			return 'online'
		elif length == '2262':
			return 'Offline'
		else:
			return 'unknown status'
	else:
		return
if __name__ == '__main__':
	print 'qq ' + 'is ' + check_qq(verify)

#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
#=============================================================================
#     FileName: check_server_status.py
#         Desc: Check server status
#       Author: tontinme
#        Email: tontinme@gmail.com
#     HomePage: http://www.tontin.me
#      Version: 1.0.1
#   LastChange: 2011-07-22 23:01:24
#      History: 2011-06-10 10:00:00
#=============================================================================
'''
#Usage:python check_server_status.py -a 192.168.1.198 -p 22
#in crontab
#Usage: 15 */1 * * * /usr/bin/python /home/tontinme/check_server_status.py -a 192.168.1.198 -p 22 >> /home/tontinme/check_server_status.log 2>&1

from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText
#from email.MIMEImage import MIMEImage
from email.header import Header
import smtplib
import socket
#import re
import sys
import time

mail_server = 'smtp.163.com'
mail_server_port = 25
from_addr = 'check_server@163.com'
to_addr = 'tontinme@gmail.com'
smtp_user = 'check_server'
smtp_pass = 'check_XXXXXX'

#from_header = 'From:%s\r\n' % from_addr
#to_header = 'To: %s\r\n\r\n' % to_addr
#subject_header = 'Subject: Oops! Your server may has encountered a problem.'

def check_server(address, port):
        s = socket.socket()
        print time.strftime('%Y-%m-%d_%H:%M:%S', time.localtime(time.time()))
        print "Attempting to connect %s on port %s" % (address, port)
        try:
                s.connect((address, port))
                print "Connected to %s on port %s successful!" % (address, port)
                return True
        except socket.error, e:
                print "Connection to %s on port %s failed: %s" % (address, port, e)
                err_msg1 = "Connection to %s on port %s failed: %s" % (address, port, e)
                err_msg2 = time.strftime('%Y-%m-%d_%H:%M:%S', time.localtime(time.time()))
                err_file = open("error-info.log", "w")
                err_file.write("-------------------------------\n")
                err_file.write(err_msg2)
                err_file.write("\n")
                err_file.write(err_msg1)
                err_file.write("\n")
                err_file.write("-------------------------------\n")
                err_file.close()
                return False
if __name__ == '__main__':
        from optparse import OptionParser
        parser = OptionParser()
        parser.add_option("-a", "--address", dest="address", default='localhost',
                        help="ADDRESS for server", metavar="ADDRESS")
        parser.add_option("-p", "--port", dest="port", type="int", default=22,
                        help="PORT for server", metavar="PORT")
(options, args) = parser.parse_args()
#print "options: %s, args: %s" % (options, args)
check = check_server(options.address, options.port)
print "check_server returned %s" % check
print '--------------------------------'
#body = "Connection to %s on port %s failed" % (options.address, options.port)
#print body
if (check != True):
        err_status = open("error-info.log", "r")
        err_info = err_status.read()
        err_status.close()
#       print err_info

        email_title='[紧急]服务器状态邮件通知'
        email_body_plain='%s' % (err_info)
        #email_body_html='<b><font color=red>%s</font></b>' % (err_info)
        msgRoot = MIMEMultipart('related')
        msgRoot['Subject'] =Header(email_title,'utf-8')
        msgRoot['From'] = from_addr
        msgRoot['To'] = to_addr
        msgAlternative = MIMEMultipart('alternative')
        msgRoot.attach(msgAlternative)
        msgText = MIMEText(email_body_plain, 'plain', 'utf-8')
        msgAlternative.attach(msgText)
        #msgText = MIMEText(email_body_html, 'html','utf-8')
        #msgAlternative.attach(msgText)

        try:
                #s_mail = smtplib.SMTP(mail_server, mail_server_port)
                s_mail = smtplib.SMTP()
                #s_mail.set_debuglevel(1)
                #s_mail.starttls()
                s_mail.connect(mail_server)
                s_mail.login(smtp_user, smtp_pass)
                s_mail.sendmail(from_addr, to_addr, msgRoot.as_string())
                s_mail.quit()
        except socket.gaierror, e:
                print "The local machine is down: %s" % e
                print "No notification has been send!"
        except:
                print "Unexpected error:"
                raise
sys.exit(not check)

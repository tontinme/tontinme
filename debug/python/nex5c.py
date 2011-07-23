#!/usr/bin/python
#coding=utf-8

import urllib2
#import sys

def get_keyword(line):
        bytenum = line.find('pricetext')
        if bytenum != -1:
                return line[bytenum:]

if __name__ == "__main__":
        #data = urllib2.urlopen('http://www.amazon.cn/%E7%B4%A2%E5%B0%BC-SONY-NEX-5CK%E9%93%B6-%E6%95%B0%E7%A0%81%E5%BE%AE%E5%8D%95%E7%9B%B8%E6%9C%BA/dp/B003U8WKEI/ref=sr_1_1?ie=UTF8&qid=1298208090&sr=8-1').read()
	amazon_url = 'http://www.amazon.cn/gp/product/B0055Q16ZM/ref=s9_simh_gw_p325_d2_i1?pf_rd_m=A1AJ19PSB66TGU&pf_rd_s=center-1&pf_rd_r=1Z83ESZEMMCVRN2Y55S2&pf_rd_t=101&pf_rd_p=58840952&pf_rd_i=899254051'
	dest_url = urllib2.urlopen(amazon_url)
	price_now = dest_url.headers.get("priceLarge")
	#print dest_url.headers
	print price_now
        #stdout_ = sys.stdout
        #sys.stdout = open('amazon','w')
        #print data
        #sys.stdout = stdout_
        #for line in data:
        #        key_phrase = get_keyword(line)
        #print key_phrase
#print linecache.getline('amazon',6)

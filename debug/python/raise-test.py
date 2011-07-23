#!/usr/bin/env python
def inputAge():
	age = input("Input your age:")
	if (age>100 or age<18):
		raise 'BadAgeError', 'out of range'
	return age
if __name__ == '__main__':
	inputAge()

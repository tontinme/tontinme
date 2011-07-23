#!/usr/bin/env python
class Time:
	def __init__(self, hours=0, minutes=0, seconds=0):
		self.hours = hours
		self.minutes = minutes
		self.seconds = seconds
	def printTime(time):
		print str(time.hours) + ":" + str(time.minutes) + ":" + str(time.seconds)
	def increment(self, seconds):
		self.seconds = seconds + self.seconds
		while self.seconds >= 60:
			self.seconds = self.seconds - 60
			self.minutes = self.minutes + 1

		while self.minutes >= 60:
			self.minutes = self.minutes - 60
			self.hours = self.hours + 1
		print str(self.hours) + ":" + str(self.minutes) + ":" + str(self.seconds)

if __name__ == '__main__':
	now = Time(10,18,35)
	now.printTime()
	now.increment(100)


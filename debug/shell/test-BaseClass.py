#!/usr/bin/env Python
class Person:
	def __init__(self,name=None, age=1, sex="men"):
		self.name  = name
		self.age = age
		self.sex = sex
	def displayInfo(self):
		print "name	:%-20s" % self.name
		print "age	:%-20s" % self.age
		print "sex	:%-20s" % self.sex
class Student(Person):
	def __init__(self, name=None, age=1, sex="men", grade=0):
		Person.__init__(self, name, age, sex)
		self.grade = grade
	def displayInfo(self):
		Person.displayInfo(self)
		print "grade	:%-20s" % self.grade

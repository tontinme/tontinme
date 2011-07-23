#!/usr/bin/env python
class Point:
	pass
class Rectangle:
	pass

def findUpperRight(rectangle):
	p = Point()
	p.x = rectangle.width + rectangle.corner.x
	p.y = rectangle.height + rectangle.corner.y
	return p
r = Rectangle()
r.width = 50.0
r.height = 70.00
r.corner = Point()
r.corner.x = 10
r.corner.y = 5

up = findUpperRight(r)
print '(' + str(up.x) + ',' + str(up.y) + ')'
	

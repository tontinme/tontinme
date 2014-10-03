Chapter 1. Data Structures and Algorithms
=====

1.1 Unpacking a Sequence into Seperate Variables
-----

    >>> p = (4, 5)
    >>> x, y = p

1.2 Unpacking Elements from Iterables of Arbitrary Length
-----

**This is avaible in Python 3.0 or later only**

    >>> *trailing, current = [1, 2, 3, 4, 5]
    >>> trailing
    [1, 2, 3, 4]
    >>> current
    5

1.3 Keeping the last N items
-----

    >>> from collections import deque
    >>> q = deque(maxlen=3)
    >>> q.append(1); q.append(2); q.append(3); q.append(5)
    >>> q
    deque([2,3,5], maxlen=3)

1.4 finding the largest or smallest N items
-----

use min() or max(), sorted(items)[:N] sorted(items)[-N:]

    >>> import heapq
    >>> nums = [1, 8, 2, 23, 7, -4, 18, 23, 42, 37, 2]
    >>> print(heapq.nlargest(3, nums)) # Prints [42, 37, 23]
    >>> print(heapq.nsmallest(3, nums)) # Prints [-4, 1, 2]

1.5 Implementing a priority queue
-----

使用heapq构造一个队列，使其输入输出时可以指定优先级

1.6 Mapping keys to multiple values in a dictionary
-----

    >>> from collections import defaultdict

1.7 Keeping dictionaries in order
-----

    >>> from collections import OrderedDict

1.8 Calculating with dictionaries
-----

    >>> prices = {'HPQ': 37.2, 'FB': 10.75, 'AAPL': 612.78, 'IBM': 205.55, 'ACME': 45.23}
    >>> print min(zip(prices.values(), prices.keys()))
    (10.75, 'FB')
    
or

    >>> [(k, prices[k]) for k in prices.keys() if prices[k] == min(prices.values())]
    >>> [('FB', 10.75)]

1.9 Finding commonalities in two dictionaries
-----

**This is avaible in Python 3.0 or later only**

    >>> a = {'y': 2, 'x': 1, 'z': 3}
    >>> b = {'y': 2, 'x': 11, 'w': 10}
    >>> a.keys() & b.keys()
    {'y', 'x'}
    >>> a.keys() - b.keys()
    {'z'}
    >>> {k:a[k] for k in a.keys() - {'z', 'w'}}
    {'y': 2, 'x': 1}

只支持keys()和items()的运算，不支持values()，但是可以先用zip()将key和value对调

以上语法在python3中被支持

1.10 Removing duplicates from a sequence while maintaining order
-----

    >>> a = [1, 5, 2, 1, 9, 1, 5, 10]
    >>> list(set(a))
    [1, 2, 10, 5, 9]
    >>> a = [ {'x':1, 'y':2}, {'x':1, 'y':3}, {'x':1, 'y':2}, {'x':2, 'y':4}]
    >>> list(set(a))
    TypeError: unhashable type: 'dict'

需要先对元素进行hashable，参见书中实例

    def dedupe(items, key=None):

1.11 Naming a slice
-----

Usage of slice()

    >>> items = [0, 1, 2, 3, 4, 5]
    >>> a = slice(2,3)
    >>> items[2:3]
    [2, 3]
    >>> items[a]
    [2, 3]

1.12 Determining the most frequently occurring items in a sequence
-----

    >>> from collections import Counter
    >>> words = ['why','are','you','not','looking','in','my','eyes']
    >>> a = Counter(words)
    >>> a.most_common(3)
    [('eyes', 1), ('looking', 1), ('are', 1)]

1.13 Sorting a list of dictionaries by a common key
-----

    >>> from operator import itemgetter
    >>> rows = [{'name':'tom', 'uid':'1001'},
	  {'name':'calker', 'uid':'1003},
	  {'name':'reus', 'uid':'1002'}]
    >>> a = sorted(rows, key=itemgetter('uid'))

or use lambda:

    >>> a = sorted(rows, key=lambda r: r['uid'])

1.14 Sorting objects without native comparison support
-----

just like 1.13

1.15 Grouping records together based on field
-----

    >>> from itertools import groupby

groubby() only examines consecutive items, failing to sort first won't group the records as you want

只是单纯的提供按指定field随机查询的话，可以使用multidict（使用from collections import defaultdict）

1.16 Filtering sequence elements
-----

    >>> mylist = [1, 4, -5, 10, -7, 2, 3, -1]
    >>> [item for item in mylist if item > 0]

1.17 Extracting a subset of a dictionary
-----

    >>> prices = {'HPQ': 37.2, 'FB': 10.75, 'AAPL': 612.78, 'IBM': 205.55, 'ACME': 45.23}
    >>> {k:prices[k] for k in prices.keys() if prices[k] > 200}

1.18 Mapping names to sequence elements
-----

    >>> from collections import namedtupe

对list or tupe中的元素进行命名，使代码更有可读性

1.19 Transforming and reducing data at the same time
-----

    >>> nums = [1, 2, 3, 4, 5]
    >>> square = lambda x: x * x
    >>> s = sum(square(x) for x in nums)

1.20 Combining multiple mappings into a single mapping
-----

**This is avaible in Python 3.0 or later only**

    >>> from collections import ChainMap
    >>> a = {'x': 1, 'z': 3 }
    >>> b = {'y': 2, 'z': 4 }
    >>> c = ChainMap(a,b)
    ChainMap({'a': 1, 'b': 2}, {'a': 3, 'c': 4})
    >>> len(c)
    3

需要注意的是，如果有重复的key，ChainMap只取第一个dict中的key，即只能对首次出现的kye进行操作，如果需要对后面的key操作，可以使用。这样会临时去掉第一个dict

    >>> c.parents
    ChainMap({'a': 3, 'c': 4})

Chapter 2. Strings and Text
=====

2.1 

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

2.1 Splitting strings on any of multiple delimeters
-----

re.split()是比split()支持更复杂分割的method

    >>> line = 'asdf fjdk; afed, fjek,asdf, foo'
    >>> import re
    >>> re.split(r'[;,\s]\s*', line)
    ['asdf', 'fjdk', 'afed', 'fjek', 'asdf', 'foo']

2.2 Matching text at the start or end of a string
-----

str.startswith() and str.endswith()

    >>> filename = 'spam.txt'
    >>> filename.endswith('txt')
    True

arg需要是string or tuple，不能是list

2.3 Matching strings using shell wildcards patterns
-----

    >>> from fnmatch import fnmatch, fnmatchcase
    >>> fnmatch('Dat45.csv', 'Dat[0-9]*')
    True

fnmatchcase大小写敏感，而fnmatch是否敏感依赖于OS

2.4 Matching and searching for text patterns
-----

str.find(), str.startswith(), str.endswith()

For more complicated matching, use regular expression and the re module

re.findall()返回所有匹配的list， re.finditer()返回匹配的iterator

需要注意的是re.match()只检查string的开头，有时会返回的结果不一定是所希望的

    >>> text = 'Today is 11/27/2012. PyCon starts 3/13/2013.'
    >>> m = datepat.match('11/27/2012abcdef')
    >>> m.group()
    '11/27/2012'

2.5 Searching and replacing text
-----

re.sub()

For more complicated substitutions, it's possible to specify a substitution callback function instead.

re.subn()返回两个变量，第一个是匹配后的结构，第二个是匹配的个数

2.6 Searching and replacing case-insensitive text
-----

    >>> re.sub('original xxxx', 'dest xxx', text, flags=re.IGNORECASE)

2.7 Specifying a regular expression for the shortest match
-----

python默认是贪婪匹配，改成非贪婪匹配需要在正则表达式后面添加'?'

    >>> re.compile(r'\"(.*?)\"')

2.8 Writing a regular expression for multiline patterns
-----

    >>> text = '''/* this is a
    ...		  multiline comment */
    ... '''
    >>> re.compile(r'/\*((?:.|\n)*?)\*/')

use (?:.|\n)

for simple cases, you can also use 're.DOTALL':

    >>> re.compile(r'/\*(.*?)\*/', re.DOTALL)

2.9 Normalizing unicode text to a standard representation
-----

import unicodetdata

2.10 Working with unicode characters in regular expressions
-----

By default, the re module is already programmed with rudimentary knowledge for certain unicode character classes.

If you’re going to do it seriously, you should consider installing the third-party regex library, which provides full support for Unicode case folding

2.11 Stripping unwanted characters from strings
-----

strip(), lstrip(), rstrip()

##Be aware that stripping does not apply to any text in the middle of a string##

    >>> s = '   hello world   \n'
    >>> s.strip()
    'hello world'

2.12 Sanitizing and cleaning up text
-----

temporary pass

2.13 Aligning text strings
-----

str.center(), str.ljust(), str.rjust()

format(), one benefit of format() is that it is not specific to strings. It works with any value.

    >>> '{:*^10s} {:*^10s}'.format('hello', 'world')
    >>> '**hello*** **world***'

##older usage##

    >>> text = 'hello world'
    >>> '%-20s' % text
    'hello world         '

2.14 Combining and Concatenating strings
-----

Use join() or '+'

The + operator works fine as a substitute for more complicated string formatting operations.

The most import thing to know is that the + operator to join a lot of strings together is grosslyg inefficient due to the memory copies 
and garbage collection that occurs.

2.15 Interpolating variables in strings
-----

Use format()

if the values to be substituted are truly found in variables, you can use the combination of `format_map()` and vars()

2.16 Reformatting text to a fixed number of columns
-----

    >>> import textwrap
    >>> text = 'xxx'
    >>> print (textwrap.fill(text, 40, initial_indent='    '))
        Look into my eyes, look into my
    eyes, the eyes, the eyes, the eyes, not
    around the eyes, don't look around the
    eyes, look into my eyes, you're under.

2.17 Handling HTML and XML entities in text
-----

html.escape()

    >>> from html.parser import HTMLParser
    >>> from xml.sax.saxutils import unescape

2.18 Tokenizing text
-----

即格式化，将字符串中的每部分根据正则匹配出来，然后命名

2.19 Writing a simple recursive descent parse
-----

temporary pass

2.20 Performing text operations on byte strings
-----

For the most part, almost all of the operations available on the text strings will work on byte strings

There are a few notable difference to be aware of

* indexing of byte strings produces integers, not individual characters

    >>> a = "hello"
    >>> b = b'hello'
    >>> a[0], b[0]
    ('h', 104)

* byte strings don’t provide a nice string representation and don’t print cleanly unless first decoded into a text string

    >>> b = b'hello world'
    >>> print (b)
    b'hello world'
    >>> print (b.decode('ascii'))
    hello world

* you need to be aware that using a byte string can change the semantics of certain operations—especially those related to the filesystem

    >>> import os
    >>> os.listdir('.')
    ['jalapeño.txt']
    >>. os.listdir(b'.')
    [b'jalapen\xcc\x83o.txt']

Chapter 3. Numbers, Dates and Times
=====

Chapter 4. Iterators and generators
=====

4.1 Manually consuming an iterator
-----

    >>> item = [1, 2, 3]
    >>> it = iter(item)
    >>> next(it)

4.2 Delegating iteration
-----

在类中定义一个__iter__属性即可

4.3 Creating new iteration patterns with generators
-----

    def frange(start, stop, step):
	  x = start
	  while x < stop:
		yield x
		x += step

4.4 Implementing the iterator protocol
-----

temporary pass

4.5 Iterating in reverse
-----

Use the built-in reversed() function

4.6 Defining generator functions with extra state
-----

temporary pass

4.7 Taking a slice of an iterator
-----

itertools.islice()

iterators and generators can't normally be sliced, because no information is known about their length(and they don't implement indexing).

4.8 Skiping the first part of an iterable
-----

itertools.dropwhile()可以过滤符合规则的行
itertools.islice()可以从指定行开始

4.9 Iterating over all possible combinations or permutations
-----

获得iterator的所有排列组合

itertools.permutations()

还有itertools.combinations(), itertools.combinations_with_replacement()

4.10 Iterating over the index-value pairs of a sequence
-----

    >>> li = ['a', 'b', 'c']
    >>> for idx, val in enumerate(li)
	  print(idx, val)

4.11 Iterating over multiple sequences simultaneously
-----

use zip()

    >>> liA = ['a', 'b', 'c']
    >>> liB = ['x', 'y', 'z']
    >>> list(zip(liA, liB))
    [('a', 'x'), ('b', 'y'), ('c', 'z')]

4.12 Iterating on items in separate containers
-----

    >>> from itertools import chain
    >>> list(chain(liA, liB))
    >>> ['a', 'b', 'c', 'x', 'y', 'z']

4.13 Creating data processing pipelines
-----

使用函数和yield解决

4.14 Flattening a nested sequence
-----

temporary pass

Use yield

    >>> items = [1, 2, [3, 4, [5, 6], 7], 8]

4.15 Iterating in sorted order over merged sorted iterables
-----

    >>> import heapq
    >>> list(heapq.merge(liA, liB))
    ['a', 'b', 'c', 'x', 'y', 'z']

heapq.merge()不会一开始就读入所有的sequences，所以面对大数据时比较省资源

4.16 Replacing infinite while loops with an iterator
-----

temporary pass

Use iter()

Chapter 5. Files and I/O
=====


5.1 Reading and writing text data
-----

read: use open() with mode rt

write: use open() with mode wt

append: use open() with mode at

with open('./access.log', 'rt') as f:   or  f = open('access.log', 'f')， 区别是前者会自动close文件，后者需要手动关闭(f.close())

读取文件时可以忽略未知编码问题引起的异常

    >>> g = open('sample.txt', 'rt', encoding='ascii', errors='ignore')

5.2 Printing to a file
-----

    >>> with open('./test.log', 'wt') as f:
    >>>	print("hello world", file=f)

5.3 Printing with a different seperator or line ending
-----

Directly use print() or use str.join()

    >>> print('ACME', 50, 91.5, sep=',', end='!!\n')
    >>> print(','.join(('ACME', '50', '91.5')))
    >>> row = ('ACME', 50, 91.5)
    >>> print(','.join(str(x) for x in row))

5.4 Reading and writing binary data
-----

use open() with mode 'rb' and 'wb'

    >>> with open('somefile.bin', 'wb') as f:
    >>>	f.write(b'Hello World')

    >>> t = 'Hello World'
    >>> f.write(t.encode('utf-8'))

5.5 Writing to a file that doesn't already exist
-----

Use 'xt' and 'xb' mode instead of 'wt' and 'wb' mode

5.6 Performing I/O operations on a string
-----

Use the io.StringIO()(be used for text data) and io.BytesIO()(be used for binary data) classes to create file-like objects that operate on string data

5.7 Reading and writing compressed datafiles
-----

Use gzip.open() with mode 'rt', 'rb', 'wt', 'wb', bz2.open() with mode 'rt', 'rb', 'wt', wb'

the compression level can be optionally using the compresslevel keyword argument 

5.8 Iterating over fixed-sized records
-----

    >>> from functools import partial
    >>> RECORD_SIZE = 32
    >>> with open('somefile.bin', 'rb') as f:
    >>>	records = iter(partial(f.read, RECORD_SIZE), b'')
    >>>	for r in records:
    >>>	    ...

5.9 Reading binary data into a mutable buffer
-----

Use readinto() method

    >>> import os.path
    >>> def read_into_buffer(filename):
    >>>	buf = bytearray(os.path.getsize(filename))
    >>>	with open('filename', 'rb') as f:
    >>>	    f.readinto(buf)
    >>>	return buf

5.10 Memory mapping binary files
-----

将文件映射到内存中，Use mmap

`mmap.ACCESS_WRITE`, `mmap.ACCESS_READ`, `mmap.ACCESS_COPY`(修改数据，但是不写原文件)

5.11 Manipulating pathnames
-----

    >>> dir(os.path)

5.12 Testing for the existence of a file
-----

    >>> dir(os.path)

5.13 Getting a directory listing
-----

获得指定目录下所有文件

    >>> os.listdir('./')

5.14 Bypassing filename encoding
-----

If you want to bypass this encoding for some reason, specify a filename using a raw byte string instead

5.15 Printing bad filenames
-----

    >>> def bad_filename(filename):
    >>>	return repr(filename)[1:-1]
    >>> try:
    >>>	print (filename)
    >>> except UnicodeEncodeError:
    >>>	print(bad_filename(filename))

5.16 Adding or changing the encoding of an already open file
-----

use io.TextIOWrapper()

5.17 Writing bytes to a text file
-----

    >>> import sys
    >>> sys.stdout.write(b'Hello\n')
    >>> ...
    >>> TypeError: must be str, not bytes
    >>> sys.stdout.buffer.write(b'Hello\n')
    Hello
    6

The I/O system is built from layers, text files are constructed by adding a unicode encoding/decoding layer on top of a bufferd 
binary-mode file. The `buffer` attribute simply points at this underlying file.

5.18 Wrapping an existing file descriptor as a file object
-----

    # create a file object, but don't close underlying fd when done
    >>> f = open(fd, 'wt', closefd=False)

On unix systems, this technique of wrapping a file descriptor can be a convenient means for putting a file-like interface on an existing
 I/O channel that was opened in a different way(e.g. pips, sockets, etc.)

5.19 Making temporary files and directories
-----

tempfile用完后，临时文件(夹)会被自动销毁

    >>> from tempfile import TemporaryFile
    >>> from tempfile import NamedTemporaryFile	    #print("filename is:" f.name)
    >>> from tempfile import TemporaryDirectory	    #print ("dirname is:" dir)

OR at a lower level, you can use `mkstemp()` and `mkdtemp()`. it’s up to you to clean up the files if you want

5.20 Communicating with serial ports
-----

    >>> import serial
    >>> ser = serial.Serial('/dev/tty.usbmodem641',	  #Device name varies
				baudrate=9600,
				bytesize=8,
				parity='N',
				stopbits=1)

5.21 Serializing python objects
-----

To dump an object to a file

    >>>import pickle
    >>> data = ...  #some python object
    >>> f = open('somefile', 'wb')
    >>> pickle.dump(data, f)

Use pickle.dumps() to dump an object to a string

To re-creaet an python object from a byte stream, use pickle.load() and pickle.loads()

Chapter 6. Data encoding and processing
=====

6.1 Reading and writing CSV data
-----

'import csv'即可获得csv文件的header和按行排列的内容

也可以使用'from collections import namedtuple'，将第一行的名称添加到各个元素中

csv的实例对象如下

csv.reader(), csv.writer(), csv.DictReader(), csv.DictWriter()

若第一行的名称含有特殊字符，或者csv的内容非string，可能需要单独处理

6.2 Reading and writing JSON data
-----

for string, use json.dumps() and json.loads()

for file, use json.dump() and json.load()

想要了解一个多层的json的结构，使用'from pprint import pprint'是个好办法

Normally, JSON decoding will create dicts or lists from the supplied data. If you want to create different kinds of objects, supply the `object_pairs_`hook or `object_hook` to json.loads()

    >>> data = json.loads(s, object_pairs_hook=OrderedDict)

let the keys to be sorted on output

    >>> data = '{"name": "ACME", "shares": 50, "price": 490.1}'
    >>> print(json.dumps(data, sort_keys=True))
    {"name": "ACME", "price": 490.1, "shares": 50}

6.3 Parsing Simple XML Data
-----

xml.etree.ElementTree

some method: find(), iterfind(), findtext()

6.4 Paring huge XML file incrementally
-----

逐步加载，逐步处理

    >>> from xml.etree.ElementTree import iterparse
    >>> def parse_and_remove(filename, path):
    >>>	...

6.5 Tuning a dictionary into XML
-----

    >>> from xml.etree.ElementTree import Element
    >>> def dict_to_xml(tag, d):
    >>>	...

6.6 Parsing, modifying, and rewriting XML
-----

You want to read an XML document, make changes to it, and then write it back out as XML

parse(), remove(), insert(), write()

6.7 Parsing XML documents with namespaces
-----

    >>> class XMLNamespaces:
    >>>	...

想要处理更多的XML特性，可以使用lxml library instead of ElementTree

6.8 Interacting with a relational database
-----

sqlite3 is built-in

6.9 Decoding and encoding hexadecimal digits
-----

hex to byte: `binascii.b2a_hex()`, base64.b16encode()
byte to hex: `binascii.a2b_hex()`, base64.b16decode()

binascii和base64的区别是后者只能输入和输出全大写字母的hex

both byte strings and unicode strings can be supplied. however unicode strings can only contain ASCII characters.

6.10 Decoding and encoding base64
-----

from bytes to base64: base64.b64encode()

from base64 to bytes: base64.b64decode()

both byte strings and unicode strings can be supplied. however unicode strings can only contain ASCII characters.

6.11 Reading and writing binary arrays of structures
-----

    >>> from struct import Struct
    >>> def write_records(records, format, f):
    >>>	...
    >>> def read_records(format, f):
    >>>	...

for extracting binary data from a larger binary array, you can use `unpack_from()`

6.12 Reading Nested and variable-sized binary structures
-----

__such data might include images, video, shapefils, and so on__

Temparary pass...

6.13 Summarizing data and preforming statistics
-----

For any kind of data analysis involving statistics, time series, and other related techniques, you should look at the 'Pandas Library'

Chapter 7. Functions
=====

7.1 Writing functions that accept any number of arguments
-----




Chapter 13. Utility scripting and system administration
=====

13.1 Accepting script input via redirections, pipes, or input files
-----

    >>> import fileinput
    >>> fileinput.input()

13.2 Terminating a program with an error message
-----

    >>> raise SystemExit('It failed!')

OR

    >>> import sys
    >>> sys.stderr.write('It failed\n')
    >>> raise SystemError(2)

13.3 Parsing command-line options
-----

argparse是推荐的用法，相比于getopt or optparse

    #search.py
    import argparse
    parser = argparse.ArgumentParser(description='Search some files')

    parser.add_argument(dest='filenames', metavar='filename', nargs='*')
    parser.add_argument('-p', '--pat', metavar='pattern', required=True,
	  dest='patterns', action='append', help='text pattern to search for')
    parser.add_argument('-v', dest='verbose', action='store_true', help='verbose mode')
    parser.add_argument('-o', dest='outfile', action='store', help='output file')
    parser.add_argument('--speed', dest='speed', action='store', choices={'slow', 'fast'},
	  default='slow', help='search speed')

    args = parser.parse_args()

    #output the collected arguments
    print(args.filenames)
    print(args.patterns)
    print(args.verbose)
    print(args.outfile)
    print(args.speed)

13.4 Prompting for a password at runtime
-----

get username

    >>> user = input('Enter your name:')

get passwd

    >>> import getpass
    >>> passwd = getpass.getpass()

    >>> sys_user = getpass.getuser()	  #getpass.getuser() doesn’t prompt the user for their username.
    Instead, it uses the current user’s login name, according to the user’s shell environment

13.5 Getting the terminal size
-----

    >>> import os
    >>> os.get_terminal_size()
    os.terminal_size(columns=90, lines=45)

13.6 Executing an external command and getting its output
-----

    >>> import subprocess
    >>> try:
    >>>	out_bytes = subprocess.check_output(['ls', '-l'], stderr=subprocess.STDOUT, timeout=5)
    >>> except subprocess.CalledProcessError as e:
    >>>	out_bytes = e.output
    >>>	code = e.returncode

该命令不依赖具体的shell环境，而是直接调用更底层的命令，比如os.execve()。不过也可以指定shell

    >>> subprocess.check_output('ls -al | wc -l', shell=True)

更复杂的，也可以使用subprocess.Popen()

13.7 Copying or moving files and directories
-----

    >>> import shutil
    >>> shutil.copytree(src, dst, ignore=shutil.ignore_patterns('*~','*.pyc'))

需要注意软链的问题。另外，python将错误信息保存在shutil.Error中

13.8 Creating and unpacking archives
-----

    >>> import shutil
    >>> shutil.unpack_archive('Python-3.3.0.tgz')
    >>> shutil.make_archive('py33', 'zip', 'Python-3.3.0')
    '/Users/beazley/Downloads/py33.zip'
    >>> shutil.get_unpack_formats()
    [('bztar', ['.bz2'], "bzip2'ed tar-file"), ('gztar', ['.tar.gz', '.tgz'], "gzip'ed tar-file"), ('tar', ['.tar'], 'uncompressed tar file'), ('zip', ['.zip'], 'ZIP file')]

13.9 Finding files by name
-----

os.walk(start)  #提供需要搜寻的目录即可

13.10 Reading configuration files
-----

    >>> from configparser import ConfigParser
    >>> cfg = ConfigParser()
    >>> cfg.read('./config.ini')

config.ini中支持'='和':'两种，且对变量没有书写的先后顺序要求，对大小写也不敏感

13.11 Adding logging to simple scripts
-----

    >>> import logging

级别：critical(), error(), warning(), info(), debug()

log的输出格式可以在logging.baseConfig()中用format变量来规定，也可以指定单独的配置文件(logging.config.fileConfig('logconfig.ini'))

13.12 Adding logging to libraries
-----

    >>> #somelib.py
    >>> import logging
    >>> log = logging.getLogger(__name__)
    >>> log.addHandler(logging.NullHandler())	    #attaches a null handler to the just created logger object. A null handler ignores all logging messages by default
    >>> def func():
    >>>	log.critical('A Critical Error')
    >>>	log.debug('A debug message')

13.13 Making a stopwatch timer
-----

利用time自定义一个time类，包含start, stop, reset等

    >>> import time
    >>> class Timer:

13.14 Putting limits on memory and cpu usage
-----

    >>> import resource
    >>> resource.getrlimit(resource.RLIMIT.CPU)
    >>> resource.setrlimit(resource.RLIMIT.CPU, (seconds, hard))

13.15 Launching a web browser
-----

    >>> import webbrowser
    >>> c = webbrowser('firefox')
    >>> c.open_new_tab('www.baidu.com')

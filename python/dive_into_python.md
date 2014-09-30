Dive Into Python
=====

Chapter 3. 内置数据类型
=====

Dictionary
-----

    >>> d = {"server":"mpilgrim", "database":"master"}
    >>> d["database"] = "pubs" 
    >>> del d["server"]
    >>> d.clear()		#清除所有元素

Dictionary是无序的，dictionary中的key是大小写敏感的，并且可以是任意数据类型

List
-----

    >>> li = ["a","b","testList","c","example"]
    >>> li[0] = "a", li["4"] = "example"
    >>> li[1:3]
    ["b","testList"]
    >>> li[3:]
    ["c","example"]
    >>> li.append("new")    #追加元素
    >>> li.insert(2,"2 element")	#追加元素到指定位置
    >>> li.extend(["two","newList"])    #连接list

append和extend方法不同，extend接受一个参数，这个参数总是一个list，并且把这个list中的每个元素添加到原list中。
append接受一个参数，这个参数可以是任意数据类型，并且简单的追加到list末尾。

    >>> li.index("example")
    >>> li.remove("b")

删除list最后一个元素，然后返回删除元素的值。这不同于remove，remove只删除不返回值

    >>> li.pop()

list运算符

    >>> li = li + ["likeExtend","aha"]
    >>> li += ["new"]
    >>> li = [1,2] *3
    [1,2,1,2,1,2]

list slice
    
    >>> seq = li[start:stop:step]
    >>> seq = li[::2]	#从li[0]开始，取所有偶数元素
    >>> seq = li[1::2]	#从li[1]开始，取所有奇数元素
    >>> seq = li[::-1]	#将li倒序输出

也可是使用li.reverse达到倒序的效果，但是reservse仅适用list，[::-1]还适用于string类型

Tuple介绍
-----

tuple是不可变的list。一旦创建了tuple，就不能已任何方式改变它

    >>> t = ("a,","B","myTuple","c","example")
    >>> t[1-3]
    ("B","myTuple")

不能向tuple中增加，删除，查找元素，但是可以使用**in**来查看一个元素是否存在于tuple中

##tuple的好处##

1. Tuple比list操作速度快。
2. 可以对不需要修改的数据进行“写保护”
3. tuple可以在dictionary中被用作key，list不行

tuple可以转换成list，反之亦然。从效果上看，tuple冻结一个list，而list解冻一个tuple

变量声明
-----

    >>> v = (a,b,c)
    >>> (x,y,z) = v	# x=a, y=b, z=c

映射list
-----

    >>> li = [1,9,8,4]
    >>> [elem*2 for elem in li]
    [2,18,16,8]
    #需要注意的是，对list的解析并不改变原始的list

    >>> param = {"a":"wo","b":"testDict","c":"newItem"}
    >>> ["%s=%s" %(k,v) for (k,v) in param.items()]

chapter 4. 自省的威力
=====

str
-----
    
    str将数据强制转换为字符串，每种数据类型都可以强制转换为字符串

and 和or
-----

使用and时，在布尔环境中从左到右演算表达式的值。 0, '', [], (), {}, None在布尔环境中为假，其他任何东西都为真，但是你可以在类中定义特定的方法使得类实例的演算值为假。

lambda
-----

lambda的函数，允许你快速定义单行的最小函数
    
    >>> g = lambda x: x*2
    >>> g(3)
    6
    >>> (lambda x: x*2)(3)
    6

lambda可以接收任意多个参数（包括可选参数）并且返回单个表达式的值。lambda函数不能包含命令，包含的表达式不能超过一个。

split
-----

    >>> s = "this is\ta\ntest"
    >>> print s.split()
    >>> print " ".join(s.split())

Chapter 5. 对象和面向对象
=====

from **module** import
-----

    >>> import types
    >>> types.FunctionType
    <type 'function'>
    >>> from types import FunctionType
    >>> FunctionType
    <type 'function'>

Caution:尽量少用from module import `*`, 因为判断一个特殊的函数或属性是从哪里来有些困难，并且会造成调试和重构的困难。

私有函数
-----

1. 私有函数不可以从它们的模块外面被调用
2. 私有类方法不能够从它们的类外面被调用
3. 私有属性不能够从它们的类外面被访问

如果一个python函数，类方法或属性的名字以两个下划线开始（但不是结束），它是私有的，其他所有的都是公有的。比如__parse 和 __setitem__，前者是私有的，后者是专有方法。

在python中，所有的专用方法（像__setitem__)和内置属性（像__doc__)遵守一个标准的命名习惯：开始和结束都有两个下划。

Chapter 6. 异常和文件处理
=====

与文件对象共事
-----

    >>> f.open()
    >>> f.tell()
    #tell告诉你在被打开文件中的当前位置
    >>> f.seed(-128,2)
    #seed方法移动到打开文件的另一位置。第二个参数指出第一个参数是什么意思：0表示移动到一个绝对位置；1表示移到一个相对位置；2表示相对于文件尾的位置
    >>> f.read()
    >>> f.close()

##写入文件##

两种模式，'write' or 'append'

    >>> f= open("test.dat","w")
    >>> f.write('test succeeded')
    >>> f.close()
    >>> f= open("test.dat","a")

Chapter 7. 正则表达式
=====

    >>> import re
    >>> s = "100 ROAD ChegongzhuangWest Road Huayuancun DisRoad"
    >>> re.sub(r"\bRoad\b","RD",s)
    '100 ROAD ChegongzhuangWest RD Huayuancun DisRoad'

* ^	  匹配字符串的开头
* $	  匹配字符串的结尾
* \b	  匹配一个单词的边界
* \d	  匹配任意数字
* \D	  匹配任意非数字字符
* x?	  匹配0次或1次x字符
* x*	  匹配0次或多次x字符
* x+	  匹配1次或多次x字符
* x{m,n}	匹配x字符，至少n次，至多m次
* (a|b|c)	匹配a或者b或者c
* (x)	  一般情况下表示一个组，你可以利用re.search函数返回对象的groups()函数获取它的值

Chapter 8. html处理
=====

Chapter 9. xml处理
=====



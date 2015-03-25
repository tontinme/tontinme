#python tips

##Decorator

decorator所实现的功能就是修改紧接decorator之后定义的函数和方法

旧式的风格:

    class C:
      def foo(cls, y):
          print "classmethod", cls, y
      foo = classmethod(foo)

使用decorator:

    def enhanced(method):
      def new(self, y):
          print "I'm enhanced"
          return method(self, y)
      return new
    class C:
      @enhanced
      def bar(self, x):
          print "some method says: ", x

举一个简单的例子

    def f1(arg):
        print "f1"
        r1 = arg()
        print r1
        return r1 + "f1"
    @f1
    def f2(arg = ""):
        print "f2"
        return arg + "f2r"
    print "start"
    print f2
    #print f2("1")  #出错, r1 = "" + "f2r", f2 = r1 + "f1"
    #print f1(None)
    print(type(f2)) #str

以上程序输出为:

    f1
    f2
    f2r
    start
    f2rf1

可以使用类或者函数作为decorator

    class myDecorator(object):
        def __init__(self, f):
            print("inside myDecorator.__init()")
            self.f = f
        def __call__(self):
            print("inside myDeorator.__call__()")
            self.f()

    @myDecorator
    def aFunction():
        print("inside aFunction()")

    print "Finished decorating aFunction()"
    aFunction()

`````
`````
    def entryExit(f):
        def new_f():
            print("Entering", f.__name__)
            f()
            print("Exited", f.__name__)
        return new_f
    @entryExit
    def funcl():
        print("hello world")

    funcl()

decorator可以做很多事情（http://wiki.python.org/moin/PythonDecoratorLibrary), 比如记忆函数，缓存，自动为类加上属性，输出函数的参数，性能分析器，同步，替换函数的实现，状态机等等。网络连接中可以用于重试，比如在connect前添加@retries(3)，即可轻松实现重连。

decorator写法(多个Decorator，带参数):

    @dec_a(params1)
    @dec_b(params2)
    @dec_c(params3)
    def method(args):
        pass

旧式写法:

    def method(args):
        pass
    method = dec_a(params1)(dec_b(params2)(dec_c(params)(method)))

举个实际的例子:

以下是一个在商场买东西，和导购互动的例子

基础版.

    def salesgirl(method):
        def serve(*args):
            print "Salesgirl:Hello, what do you want?", method.__name__
            result = method(*args)
            if result:
                print "Salesgirl: This shirt is 50$."
            else:
                print "Salesgirl: Well, how about trying another style?"
            return result
        return serve

    @salesgirl
    def try_this_shirt(size):
        if size < 35:
            print "I: %d inches is to small to me" %(size)
            return False
        else:
            print "I:%d inches is just enough" %(size)
            return True
    result = try_this_shirt(38)
    print "Mum:do you want to buy this?", result

输出为

    Salesgirl:Hello, what do you want? try_this_shirt
    I:38 inches is just enough
    Salesgirl: This shirt is 50$.
    Mum:do you want to buy this? True

添加导购让利的部分，用到带参数的decorator

    def salesgirl(discount):
        def expense(method):
            def serve(*args):
                print "Salesgirl: Hello what do you want?", method.__name__
                result = method(*args)
                if result:
                    print "Salesgirl: This shirt is 50$. As an old user, we promised to discount at %d%%" %(discount)
                else:
                    print "Salesgirl: Well, how about trying another one?"
                return result
            return serve
        return expense

    @salesgirl(50)
    def try_this_shirt(size):
        if size < 35:
            print "I: %d inches is too small to me" %(size)
            return False
        else:
            print "I: %d inches is just enough" %(size)
            return True
    result = try_this_shirt(38)
    print "Mum: do you want to buy this shirt?", result

输出为:

    Salesgirl:Hello, what do you want? try_this_shirt
    I:38 inches is just enough
    Salesgirl: This shirt is 50$.As an old user, we promised to discount at 50%
    Mum:do you want to buy this? True

使用decorator可以添加或删除方法

    def flaz(self): return 'flaz'     # Silly utility method
    def flam(self): return 'flam'     # Another silly method

    def change_methods(new):
        "Warning: Only decorate the __new__() method with this decorator"
        if new.__name__ != '__new__':
            return new  # Return an unchanged method
        def __new__(cls, *args, **kws):
            cls.flaz = flaz
            cls.flam = flam
            if hasattr(cls, 'say'): del cls.say
            return super(cls.__class__, cls).__new__(cls, *args, **kws)
        return __new__

    class Foo(object):
        @change_methods
        def __new__(): pass
        def say(self): print "Hi me:", self

    foo = Foo()
    print foo.flaz()  # prints: flaz
    foo.say()         # AttributeError: 'Foo' object has no attribute 'say'

该decorator为class Foo添加了flaz()和flam()方法，去掉了say()这个instance method

使用decorator修改调用模型

    def elementwise(fn):
        def newfn(arg):
            if hasattr(arg,'__getitem__'):  # is a Sequence
                return type(arg)(map(fn, arg))
            else:
                return fn(arg)
        return newfn

    @elementwise
    def compute(x):
        return x**3 - 1

    print compute(5)        # prints: 124
    print compute([1,2,3])  # prints: [0, 7, 26]
    print compute((1,2,3))  # prints: (0, 7, 26)

compute()原本是不支持对sequence进行操作的，通过添加decorator，实现了该操作


**参考资料**：

`http://blog.sina.com.cn/s/blog_571b19a001013h7j.html`

http://www.cnblogs.com/SeasonLee/archive/2010/04/24/1719444.html

http://www.ibm.com/developerworks/cn/linux/l-cpdecor.html

##Metaclass



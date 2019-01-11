# Chapter 3 - Mocks

{icon: quote-right}
B> _We're gonna get bloody on this one, Rog._
B> - Lethal Weapon (1987)

## Basic concepts

As we saw in the previous chapter the relationship between the component that we are testing and other components of the system can be complex. Sometimes idempotency and isolation are not easy to achieve, and testing outgoing commands requires to check the parameters sent to the external component, which is not trivial.

The main difficulty comes from the fact that your code is actually using the external system. When you run it in production the external system will provide the data that your code needs and the whole process can work as intended. During testing, however, you don't want to be bound to the external system, for the reasons explained in the previous chapter, but at the same time you need it to make your code work.

So, you face a complex issue. On the one hand your code is connected to the external system (be it hardcoded or chosen programmatically), but on the other hand you want it to run without the external system being active (or even present).

This problem can be solved with the use of mocks. A mock, in the testing jargon, is an object that simulates the behaviour of another (more complex) object. Wherever your code connects to an external system, during testing you can replace the latter with a mock, pretending the external system is there and properly checking that your component behaves like intended.

## First steps

Let us try and work with a mock in Python and see what it can do. First of all fire up a Python shell and import the library 

``` python
>>> from unittest import mock
```

The main object that the library provides is `Mock` and you can instantiate it without any argument

``` python
>>> m = mock.Mock()
```

This object has the peculiar property of creating methods and attributes on the fly when you require them. Let us first look inside the object to get an idea of what it provides

``` python
>>> dir(m)
['assert_any_call', 'assert_called_once_with', 'assert_called_with', 'assert_has_calls', 'attach_mock', 'call_args', 'call_args_list', 'call_count', 'called', 'configure_mock', 'method_calls', 'mock_add_spec', 'mock_calls', 'reset_mock', 'return_value', 'side_effect']
```

As you can see there are some methods which are already defined into the `Mock` object. Let's try to read a non-existent attribute

``` python
>>> m.some_attribute
<Mock name='mock.some_attribute' id='140222043808432'>
>>> dir(m)
['assert_any_call', 'assert_called_once_with', 'assert_called_with', 'assert_has_calls', 'attach_mock', 'call_args', 'call_args_list', 'call_count', 'called', 'configure_mock', 'method_calls', 'mock_add_spec', 'mock_calls', 'reset_mock', 'return_value', 'side_effect', 'some_attribute']
```

As you can see this class is somehow different from what you are used to. First of all, its instances do not raise an `AttributeError` when asked for a non-existent attribute, but they happily return another instance of `Mock` itself. Second, the attribute you tried to access has now been created inside the object and accessing it returns the same mock object as before.
 
``` python
>>> m.some_attribute
<Mock name='mock.some_attribute' id='140222043808432'>
```

Mock objects are callables, which means that they may act both as attributes and as methods. If you try to call the mock it just returns another mock with a name that includes parentheses to signal its callable nature

``` python
>>> m.some_attribute()
<Mock name='mock.some_attribute()' id='140247621475856'>
```

As you can understand, such objects are the perfect tool to mimic other objects or systems, since they may expose any API without raising exceptions. To use them in tests, however, we need them to behave just like the original, which implies returning sensible values or performing real operations.
 
## Simple return values

The simplest thing a mock can do for you is to return a given value every time you call one of its methods. This is configured setting the `return_value` attribute of a mock object

``` python
>>> m.some_attribute.return_value = 42
>>> m.some_attribute()
42
```

Now, as you can see the object does not return a mock object any more, instead it just returns the static value stored in the `return_value` attribute. Since in Python everything is an object you can return here any type of value: simple types like an integer of a string, more complex structures like dictionaries or lists, classes that you defined, instances of those, or functions.

Pay attention that what the mock returns is exactly the object that it is instructed to use as return value. If the return value is a callable such as a function, calling the mock will return the function itself and not the result of the function. Let me give you an example

``` python
>>> def print_answer():
...  print("42")
... 
>>> 
>>> m.some_attribute.return_value = print_answer
>>> m.some_attribute()
<function print_answer at 0x7f8df1e3f400>
```

As you can see calling `some_attribute()` just returns the value stored in `return_value`, that is the function itself. To make the mock call the object that we use as a return value we have to use a slightly more complex attribute called `side_effect`.

## Complex return values

The `side_effect` parameter of mock objects is a very powerful tool. It accepts three different flavours of objects: callables, iterables, and exceptions, and changes its behaviour accordingly.

If you pass an exception the mock will raise it
 
``` python
>>> m.some_attribute.side_effect = ValueError('A custom value error')
>>> m.some_attribute()
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "/usr/lib/python3.6/unittest/mock.py", line 939, in __call__
    return _mock_self._mock_call(*args, **kwargs)
  File "/usr/lib/python3.6/unittest/mock.py", line 995, in _mock_call
    raise effect
ValueError: A custom value error
```

If you pass an iterable, such as for example a generator, a plain list, tuple, or similar objects, the mock will yield the values of that iterable, i.e. return every value contained in the iterable on subsequent calls of the mock.

``` python
>>> m.some_attribute.side_effect = range(3)
>>> m.some_attribute()
0
>>> m.some_attribute()
1
>>> m.some_attribute()
2
>>> m.some_attribute()
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "/usr/lib/python3.6/unittest/mock.py", line 939, in __call__
    return _mock_self._mock_call(*args, **kwargs)
  File "/usr/lib/python3.6/unittest/mock.py", line 998, in _mock_call
    result = next(effect)
StopIteration
```

As promised, the mock just returns every object found in the iterable (in this case a `range` object) one at a time until the generator is exhausted. According to the iterator protocol once every item has been returned the object raises the `StopIteration` exception, which means that you can safely use it in a loop.

Last, if you feed `side_effect` a callable, the latter will be executed with the parameters passed when calling the attribute. Let's consider again the simple example given in the previous section

``` python
>>> def print_answer():
...     print("42")       
>>> m.some_attribute.side_effect = print_answer
>>> m.some_attribute()
42
```

A slightly more complex example is that of a function with arguments

``` python
>>> def print_number(num):
...     print("Number:", num)
... 
>>> m.some_attribute.side_effect = print_number
>>> m.some_attribute(5)
Number: 5
```

As you can see the arguments passed to the attribute are directly used as arguments for the stored function. This is very powerful, especially if you stop thinking about "functions" and start considering "callables". Indeed, given the nature of Python objects we know that instantiating an object is not different from calling a function, which means that `side_effect` can be given a class and return a instance of it

``` python
>>> class Number:
...     def __init__(self, value):
...         self._value = value
...     def print_value(self):
...         print("Value:", self._value)
... 
>>> m.some_attribute.side_effect = Number
>>> n = m.some_attribute(26)
>>> n
<__main__.Number object at 0x7f8df1aa4470>
>>> n.print_value()
Value: 26
```

## Asserting calls

As I explained in the previous chapter outgoing commands shall be tested checking the correctness of the message argument. This can be easily done with mocks, as these objects record every call that they receive and the arguments passed to it.

Let's see a practical example

``` python
from unittest import mock
import myobj


def test_connect():
    external_obj = mock.Mock()
    myobj.MyObj(external_obj)
    external_obj.connect.assert_called_with()
```

Here, the `myobj.MyObj` class needs to connect to an external object, for example a remote repository or a database. The only thing we need to know for testing purposes is if the class called the `connect` method of the external object without any parameter.
 
So the first thing we do in this test is to instantiate the mock object. This is a fake version of the external object, and its only purpose is to accept calls from the `MyObj` object under test and possibly return sensible values. Then we instantiate the `MyObj` class passing the external object. We expect the class to call the `connect` method so we express this expectation calling `external_obj.connect.assert_called_with()`.

What happens behind the scenes? The `MyObj` class receives the fake external object and somewhere in its initialization process calls the `connect` method of the mock object. This call creates the method itself as a mock object. This new mock records the parameters used to call it and the subsequent call to its `assert_called_with` method checks that the method was called and that no parameters were passed.

In this case an object like

``` python
class MyObj():
    def __init__(self, repo):
        repo.connect()
```

would pass the test, as the object passed as `repo` is a mock that does nothing but record the calls. As you can see, the `__init__()` method actually calls `repo.connect()`, and `repo` is expected to be a full-featured external object that provides `connect` in its API. Calling `repo.connect()` when `repo` is a mock object, instead, silently creates the method (as another mock object) and records that the method has been called once without arguments.

The `assert_called_with` method allows us to also check the parameters we passed when calling. To show this let us pretend that we expect the `MyObj.setup` method to call `setup(cache=True, max_connections=256)` on the external object. Remember that this is an outgoing command, so we are interested in checking the parameters and not the result.

The new test can be something like

``` python
def test_setup():
    external_obj = mock.Mock()
    obj = myobj.MyObj(external_obj)
    obj.setup()
    external_obj.setup.assert_called_with(cache=True, max_connections=256)
```

In this case an object that passes the test can be

``` python
class MyObj():
    def __init__(self, repo):
        self._repo = repo
        repo.connect()

    def setup(self):
        self._repo.setup(cache=True, max_connections=256)
```

If we change the `setup` method to

```
    def setup(self):
        self._repo.setup(cache=True)
```

the test will fail with the following error

``` sh
E           AssertionError: Expected call: setup(cache=True, max_connections=256)
E           Actual call: setup(cache=True)
```

Which I consider a very clear explanation of what went wrong during the test execution.

As you can read in the official documentation, the `Mock` object provides other methods and attributes, like `assert_called_once_with`, `assert_any_call`, `assert_has_calls`, `assert_not_called`, `called`, `call_count`, and many others. Each of those explores a different aspect of the mock behaviour concerning calls. Make sure to read their description and go through the examples.

## A simple example

To learn how to use mocks in a practical case, let's work together on a new module in the `calc` package. The target is to write a class that downloads a JSON file with data on meteorites and computes some statistics on the dataset using the `Calc` class. The file is provided by NASA at [this URL](https://data.nasa.gov/resource/y77d-th95.json).

The class contains a `get_data` method that queries the remote server and returns the data, and a method `average_mass` that uses the `Calc.avg` method to compute the average mass of the meteorites and return it. In a real world case, like for example in a scientific application, I would probably split the class in two. One class manages the data, updating it whenever it is necessary, and another one manages the statistics. For the sake of simplicity, however, I will keep the two functionalities together in this example.

Let's see a quick example of what is supposed to happen inside our code. An excerpt of the file provided from the server is

``` json
[
    {
        "fall": "Fell",
        "geolocation": {
            "type": "Point",
            "coordinates": [6.08333, 50.775]
        },
        "id":"1",
        "mass":"21",
        "name":"Aachen",
        "nametype":"Valid",
        "recclass":"L5",
        "reclat":"50.775000",
        "reclong":"6.083330",
        "year":"1880-01-01T00:00:00.000"
    },
    {
        "fall": "Fell",
        "geolocation": {
            "type": "Point",
            "coordinates": [10.23333, 56.18333]
        },
        "id":"2",
        "mass":"720",
        "name":"Aarhus",
        "nametype":"Valid",
        "recclass":"H6",
        "reclat":"56.183330",
        "reclong":"10.233330",
        "year":"1951-01-01T00:00:00.000"
    }
]
```

So a good way to compute the average mass of the meteorites is

``` python
import urllib.request
import json

import calc

URL = ("https://data.nasa.gov/resource/y77d-th95.json")

with urllib.request.urlopen(URL) as url:
    data = json.loads(url.read().decode())

masses = [float(d['mass']) for d in data if 'mass' in d]

print(masses)

avg_mass = calc.Calc().avg(masses)

print(avg_mass)
```

Where the list comprehension filters out those elements which do not have a `mass` attribute.

An initial test for our class might be

``` python
def test_average_mass():
    m = MeteoriteStats()
    data = m.get_data()

    assert m.average_mass(data) == 50190.19568930039
```

This little test contains however two big issues. First of all the `get_data` method is supposed to use the Internet connection to get the data from the server. This is a typical example of an outgoing query, as we are not trying to change the state of the web server providing the data. You already know that you should not test the return value of an outgoing query, but you can see here why you shouldn't use real data when testing either. The data coming from the server can change in time, and this can invalidate your tests. 

In this case, however, testing the code is simple. Since the class has a public method `get_data` that interacts with the external component, it is enough to temporarily replace it with a mock that provides sensible values. Create the `tests/test_meteorites.py` file and put this code in it

``` python
from unittest import mock

from calc.meteorites import MeteoriteStats


def test_average_mass():
    m = MeteoriteStats()
    m.get_data = mock.Mock()
    m.get_data.return_value = [
        {
            "fall": "Fell",
            "geolocation": {
                "type": "Point",
                "coordinates": [6.08333, 50.775]
            },
            "id":"1",
            "mass":"21",
            "name":"Aachen",
            "nametype":"Valid",
            "recclass":"L5",
            "reclat":"50.775000",
            "reclong":"6.083330",
            "year":"1880-01-01T00:00:00.000"},
        {
            "fall": "Fell",
            "geolocation": {
                "type": "Point",
                "coordinates": [10.23333, 56.18333]
            },
            "id":"2",
            "mass":"720",
            "name":"Aarhus",
            "nametype":"Valid",
            "recclass":"H6",
            "reclat":"56.183330",
            "reclong":"10.233330",
            "year":"1951-01-01T00:00:00.000"
        }
    ]

    avgm = m.average_mass(m.get_data())

    assert avgm == 370.5
```

When we run this test we are not testing that the external server provides the correct data. We are testing the process implemented by `average_mass`, feeding the algorithm some known input. This is not different from the first tests that we implemented: in that case we were testing an addition, here we are testing a more complex algorithm, but the concept is the same.

We can now write a class that passes this test

``` python
import urllib.request
import json

from calc import calc

URL = ("https://data.nasa.gov/resource/y77d-th95.json")


class MeteoriteStats:
    def get_data(self):
        with urllib.request.urlopen(URL) as url:
            return json.loads(url.read().decode())

    def average_mass(self, data):
        c = calc.Calc()
        masses = [float(d['mass']) for d in data if 'mass' in d]

        return c.avg(masses)
```

Please note that we are not testing the `get_data` method itself. That method uses the function `urllib.request.urlopen` that opens an Internet connection without passing through any other public object that we can replace at run time during the test. We need then a tool to replace "internal" parts of our objects when we run them, and this is provided by patching.

{icon: github}
B> Git tag: [meteoritestats-class-added](https://github.com/pycabook/calc/tree/meteoritestats-class-added)

## Patching

Mocks are very simple to introduce in your tests whenever your objects accept classes or instances from outside. In that case, as shown in the previous sections, you just have to instantiate the `Mock` class and pass the resulting object to your system. However, when the external classes instantiated by your library are hardcoded this simple trick does not work. In this case you have no chance to pass a fake object instead of the real one.

This is exactly the case addressed by patching. Patching, in a testing framework, means to replace a globally reachable object with a mock, thus achieving the goal of having the code run unmodified, while part of it has been hot swapped, that is, replaced at run time.

### A warm-up example

Let us start with a very simple example. Patching can be complex to grasp at the beginning so it is better to start learning it with trivial use cases.

Create a new project following the instructions given previously in the book, calling this project `fileinfo`. The purpose of this library is to develop a simple class that returns information about a given file. The class shall be instantiated with the file path, which can be relative.

The starting point is the class with the `__init__` method. If you want you can develop the class using TDD, but for the sake of brevity I will not show here all the steps that I followed. This is the set of tests I have in `tests/test_fileinfo.py`

``` python
from fileinfo.fileinfo import FileInfo


def test_init():
    filename = 'somefile.ext'
    fi = FileInfo(filename)
    assert fi.filename == filename


def test_init_relative():
    filename = 'somefile.ext'
    relative_path = '../{}'.format(filename)
    fi = FileInfo(relative_path)
    assert fi.filename == filename
```

and this is the code of the `FileInfo` class in the `fileinfo/fileinfo.py` file

``` python
import os


class FileInfo:
    def __init__(self, path):
        self.original_path = path
        self.filename = os.path.basename(path)
```

{icon: github}
B> Git tag: [first-version](https://github.com/pycabook/fileinfo/tree/first-version)

As you can see the class is extremely simple, and the tests are straightforward. So far I didn't add anything new to what we discussed in the previous chapter.

Now I want the `get_info()` function to return a tuple with the file name, the original path the class was instantiated with, and the absolute path of the file. Pretending we are in the `/some/absolute/path` directory, the class should work as shown here

``` python
>>> fi = FileInfo('../book_list.txt')
>>> fi.get_info()
('book_list.txt', '../book_list.txt', '/some/absolute')
```

You can immediately realise that you have an issue in writing the test. There is no way to easily test something as "the absolute path", since the outcome of the function called in the test is supposed to vary with the path of the test itself. Let us try to write part of the test

``` python
def test_get_info():
    filename = 'somefile.ext'
    original_path = '../{}'.format(filename)
    fi = FileInfo(original_path)
    assert fi.get_info() == (filename, original_path, '???')
```

where the `'???'` string highlights that I cannot put something sensible to test the absolute path of the file.

Patching is the way to solve this problem. You know that the function will use some code to get the absolute path of the file. So, within the scope of this test only, you can replace that code with something different and perform the test. Since the replacement code has a known outcome writing the test is now possible.

Patching, thus, means to inform Python that during the execution of a specific portion of the code you want a globally accessible module/object replaced by a mock. Let's see how we can use it in our example

``` python
from unittest.mock import patch

[...]

def test_get_info():
    filename = 'somefile.ext'
    original_path = '../{}'.format(filename)

    with patch('os.path.abspath') as abspath_mock:
        test_abspath = 'some/abs/path'
        abspath_mock.return_value = test_abspath
        fi = FileInfo(original_path)
        assert fi.get_info() == (filename, original_path, test_abspath)
```

You clearly see the context in which the patching happens, as it is enclosed in a `with` statement. Inside this statement the module `os.path.abspath` will be replaced by a mock created by the function `patch` and called `abspath_mock`. So, while Python executes the lines of code enclosed by the `with` statement any call to `os.path.abspath` will return the `abspath_mock` object.

The first thing we can do, then, is to give the mock a known `return_value`. This way we solve the issue that we had with the initial code, that is using an external component that returns an unpredictable result. The line

``` python
        abspath_mock.return_value = test_abspath
```

instructs the patching mock to return the given string as a result, regardless of the real values of the file under consideration. 

The code that make the test pass is

``` python
class FileInfo:
    [...]

    def get_info(self):
        return (
            self.filename,
            self.original_path,
            os.path.abspath(self.filename)
        )
```

When this code is executed by the test the `os.path.abspath` function is replaced at run time by the mock that we prepared there, which basically ignores the input value `self.filename` and returns the fixed value it was instructed to use.

{icon: github}
B> Git tag: [patch-with-context-manager](https://github.com/pycabook/fileinfo/tree/patch-with-context-manager)

It is worth at this point discussing outgoing messages again. The code that we are considering here is a clear example of an outgoing query, as the `get_info` method is not interested in changing the status of the external component. In the previous chapter we reached the conclusion that testing the return value of outgoing queries is pointless and should be avoided. With `patch` we are replacing the external component with something that we know, using it to test that our object correctly handles the value returned by the outgoing query. We are thus not testing the external component, as it got replaced, and definitely we are not testing the mock, as its return value is already known.

Obviously to write the test you have to know that you are going to use the `os.path.abspath` function, so patching is somehow a "less pure" practice in TDD. In pure OOP/TDD you are only concerned with the external behaviour of the object, and not with its internal structure. This example, however, shows that this pure approach has some limitations that you have to cope with, and patching is a clean way to do it.

## The patching decorator

The `patch` function we imported from the `unittest.mock` module is very powerful, as it can temporarily replace an external object. If the replacement has to or can be active for the whole test, there is a cleaner way to inject your mocks, which is to use `patch` as a function decorator.

This means that you can decorate the test function, passing as argument the same argument you would pass if  `patch` was used in a `with` statement. This requires however a small change in the test function prototype, as it has to receive an additional argument, which will become the mock.

Let's change `test_get_info`, removing the `with` statement and decorating the function with `patch`

``` python
@patch('os.path.abspath')
def test_get_info(abspath_mock):
    test_abspath = 'some/abs/path'
    abspath_mock.return_value = test_abspath

    filename = 'somefile.ext'
    original_path = '../{}'.format(filename)

    fi = FileInfo(original_path)
    assert fi.get_info() == (filename, original_path, test_abspath)
```

{icon: github}
B> Git tag: [patch-with-function-decorator](https://github.com/pycabook/fileinfo/tree/patch-with-function-decorator)

As you can see the `patch` decorator works like a big `with` statement for the whole function. The `abspath_mock` argument passed to the test becomes internally the mock that replaces `os.path.abspath`. Obviously this way you replace `os.path.abspath` for the whole function, so you have to decide case by case which form of the `patch` function you need to use.

## Multiple patches

You can patch more that one object in the same test. For example, consider the case where the `get_info` method calls `os.path.getsize` in addition to `os.path.abspath`, because it needs it to return the size of the file. You have at this point two different outgoing queries, and you have to replace both with mocks to make your class work during the test.

This can be easily done with an additional `patch` decorator

``` python
@patch('os.path.getsize')
@patch('os.path.abspath')
def test_get_info(abspath_mock, getsize_mock):
    filename = 'somefile.ext'
    original_path = '../{}'.format(filename)

    test_abspath = 'some/abs/path'
    abspath_mock.return_value = test_abspath

    test_size = 1234
    getsize_mock.return_value = test_size

    fi = FileInfo(original_path)
    assert fi.get_info() == (filename, original_path, test_abspath, test_size)
```

Please note that the decorator which is nearest to the function is applied first. Always remember that the decorator syntax with `@` is a shortcut to replace the function with the output of the decorator, so two decorators result in

``` python
@decorator1
@decorator2
def myfunction():
    pass
```

which is a shorcut for

``` python
def myfunction():
    pass
myfunction = decorator1(decorator2(myfunction))
```

This explains why, in the test code, the function receives first `abspath_mock` and then `getsize_mock`. The first decorator applied to the function is the patch of `os.path.abspath`, which appends the mock that we call `abspath_mock`. Then the patch of `os.path.getsize` is applied and this appends its own mock.

The code that makes the test pass is

``` python
class FileInfo:
    [...]

    def get_info(self):
        return (
            self.filename,
            self.original_path,
            os.path.abspath(self.filename),
            os.path.getsize(self.filename)
        )
```

{icon: github}
B> Git tag: [multiple-patches](https://github.com/pycabook/fileinfo/tree/multiple-patches)

We can write the above test using two `with` statements as well

``` python
def test_get_info():
    filename = 'somefile.ext'
    original_path = '../{}'.format(filename)

    with patch('os.path.abspath') as abspath_mock:
        test_abspath = 'some/abs/path'
        abspath_mock.return_value = test_abspath

        with patch('os.path.getsize') as getsize_mock:
            test_size = 1234
            getsize_mock.return_value = test_size

            fi = FileInfo(original_path)
            assert fi.get_info() == (
                filename,
                original_path,
                test_abspath,
                test_size
            )
```

Using more than one `with` statement, however, makes the code difficult to read, in my opinion, so in general I prefer to avoid complex `with` trees if I do not really need to use a limited scope of the patching.

## Patching immutable objects

The most widespread version of Python is CPython, which is written, as the name suggests, in C. Part of the standard library is also written in C, while the rest is written in Python itself.

The objects (classes, modules, functions, etc.) that are implemented in C are shared between interpreters[^interpreters], and this requires those objects to be immutable, so that you cannot alter them at runtime from a single interpreter.

[^interpreters]: having multiple interpreters is something that you achieve embedding the Python interpreter in a C program, for example.

An example of this immutability can be given easily using a Python console

``` python
>>> a = 1
>>> a.conjugate = 5
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
AttributeError: 'int' object attribute 'conjugate' is read-only
```

Here I'm trying to replace a method with an integer, which is pointless, but nevertheless shows the issue we are facing.

What has this immutability to do with patching? What `patch` does is actually to temporarily replace an attribute of an object (method of a class, class of a module, etc.), which also means that if we try to replace an attribute in an immutable object the patching action will fail.

A typical example of this problem is the `datetime` module, which is also one of the best candidates for patching, since the output of time functions is by definition time-varying.

Let me show the problem with a simple class that logs operations. I will temporarily break the TDD methodology writing first the class and then the tests, so that you can appreciate the problem.

Create a file called `logger.py` and put there the following code

``` python
import datetime


class Logger:
    def __init__(self):
        self.messages = []

    def log(self, message):
        self.messages.append((datetime.datetime.now(), message))
```

This is pretty simple, but testing this code is problematic, because the `log()` method produces results that depend on the actual execution time. The call to `datetime.datetime.now` is however an outgoing query, and as such it can be replaced by a mock with `patch`.

If we try to do it, however, we will have a bitter surprise. This is the test code, that you can put in `tests/test_logger.py`

``` python
from unittest.mock import patch

from fileinfo.logger import Logger


@patch('datetime.datetime.now')
def test_log(mock_now):
    test_now = 123
    test_message = "A test message"
    mock_now.return_value = test_now

    test_logger = Logger()
    test_logger.log(test_message)
    assert test_logger.messages == [(test_now, test_message)]
```

When you try to execute this test you will get the following error

``` txt
TypeError: can't set attributes of built-in/extension type 'datetime.datetime'
```

which is raised because patching tries to replace the `now` function in `datetime.datetime` with a mock, and since the module is immutable this operation fails.

{icon: github}
B> Git tag: [initial-logger-not-working](https://github.com/pycabook/fileinfo/tree/initial-logger-not-working)

There are several ways to address this problem. All of them, however, start from the fact that importing or subclassing an immutable object gives you a mutable "copy" of that object.

The easiest example in this case is the module `datetime` itself. In the `test_log` function we tried to patch directly the `datetime.datetime.now` object, affecting the builtin module `datetime`. The file `logger.py`, however, does import `datetime`, so this latter becomes a local symbol in the `logger` module. This is exactly the key for our patching. Let us change the code to

``` python
@patch('fileinfo.logger.datetime.datetime')
def test_log(mock_datetime):
    test_now = 123
    test_message = "A test message"
    mock_datetime.now.return_value = test_now

    test_logger = Logger()
    test_logger.log(test_message)
    assert test_logger.messages == [(test_now, test_message)]
```

{icon: github}
B> Git tag: [correct-patching](https://github.com/pycabook/fileinfo/tree/correct-patching)

If you run the test now, you can see that the patching works. What we did was to inject our mock in `fileinfo.logger.datetime.datetime` instead of `datetime.datetime.now`. Two things changed, thus, in our test. First, we are patching the module imported in the `logger.py` file and not the module provided globally by the Python interpreter. Second, we have to patch the whole module because this is what is imported by the `logger.py` file. If you try to patch `fileinfo.logger.datetime.datetime.now` you will find that it is still immutable.

Another possible solution to this problem is to create a function that invokes the immutable object and returns its value. This last function can be easily patched, because it just uses the builtin objects and thus is not immutable. This solution, however, requires changing the source code to allow testing, which is far from being optimal. Obviously it is better to introduce a small change in the code and have it tested than to leave it untested, but whenever is possible I try as much as possible to avoid solutions that introduce code which wouldn't be required without tests.

## Mocks and proper TDD

Following a strict TDD methodology means writing a test before writing the code that passes that test. This can be done because we use the object under test as a black box, interacting with it through its API, and thus not knowing anything of its internal structure.

When we mock systems we break this assumption. In particular we need to open the black box every time we need to patch an hardcoded external system. Let's say, for example, that the object under test creates a temporary directory to perform some data processing. This is a detail of the implementation and we are not supposed to know it while testing the object, but since we need to mock the file creation to avoid interaction with the external system (storage) we need to become aware of what happens internally.

This also means that writing a test for the object before writing the implementation of the object itself is difficult. Pretty often, thus, such objects are built with TDD but iteratively, where mocks are introduced after the code has been written.

While this is a violation of the strict TDD methodology, I don't consider it a bad practice. TDD helps us to write better code consistently, but good code can be written even without tests. The real outcome of TDD is a test suite that is capable of detecting regressions or the removal of important features in the future. This means that breaking strict TDD for a small part of the code (patching objects) will not affect the real result of the process, only change the way we achieve it.

## A warning

Mocks are a good way to approach parts of the system that are not under test but that are still part of the code that we are running. This is particularly true for parts of the code that we wrote, which internal structure is ultimately known. When the external system is complex and completely detached from our code, mocking starts to become complicated and the risk is that we spend more time faking parts of the system than actually writing code.

In this cases we definitely crossed the barrier between unit testing and integration testing. You may see mocks as the bridge between the two, as they allow you to keep unit-testing parts that are naturally connected ("integrated") with external systems, but there is a point where you need to recognise that you need to change approach.

This threshold is not fixed, and I can't give you a rule to recognise it, but I can give you some advice. First of all keep an eye on how many things you need to mock to make a test run, as an increasing number of mocks in a single test is definitely a sign of something wrong in the testing approach. My rule of thumb is that when I have to create more than 3 mocks, an alarm goes off in my mind and I start questioning what I am doing.

The second advice is to always consider the complexity of the mocks. You may find yourself patching a class but then having to create monsters like `cls_mock().func1().func2().func3.assert_called_with(x=42)` which is a sign that the part of the system that you are mocking is deep into some code that you cannot really access, because you don't know it's internal mechanisms. This is the case with ORMs, for example, and I will discuss it later in the book.

The third advice is to consider mocks as "hooks" that you throw at the external system, and that break its hull to reach its internal structure. These hooks are obviously against the assumption that we can interact with a system knowing only its external behaviour, or its API. As such, you should keep in mind that each mock you create is a step back from this perfect assumption, thus "breaking the spell" of the decoupled interaction. Doing this you will quickly become annoyed when you have to create too many mocks, and this will contribute in keeping you aware of what you are doing (or overdoing).

## Recap

Mocks are a very powerful tool that allows us to test code that contains outgoing messages. In particular they allow us to test the arguments of outgoing commands. Patching is a good way to overcome the fact that some external components are hardcoded in our code and are thus unreachable through the arguments passed to the classes or the methods under analysis.

Mocks are also the most complex part of testing, so don't be surprised if you are still a bit confused by them. Review the chapter once, maybe, but then try to go on, as in later chapters we will use mocks in very simple and practical examples, which may shed light upon the whole matter.

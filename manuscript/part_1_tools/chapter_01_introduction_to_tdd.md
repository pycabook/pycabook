# Chapter 1 - Introduction to TDD

{icon: quote-right}
B> _Why worry? Each one of us is wearing an unlicensed nuclear accelerator on his back._
B> - Ghostbusters (1984)

## Introduction

"Test-Driven Development" (TDD) is fortunately one of the names that I can spot most frequently when people talk about methodologies. Unfortunately, many programmers still do not follow it, fearing that it will impose a further burden on the already difficult life of the developer.

In this chapter I will try to outline the basic concept of TDD and to show you how your job as a programmer can greatly benefit from it. I will develop a very simple project to show how to practically write software following this methodology.

TDD is a methodology, something that can help you to create better code. But it is not going to solve all your problems. As with all methodologies you have to pay attention not to commit blindly to it. Try to understand the reasons why certain practices are suggested by the methodology and you will also understand when and why you can or have to be flexible.

Keep also in mind that testing is a broader concept that doesn't end with TDD. This latter focuses a lot on unit testing, which is a specific type of test that helps you to develop the API of your library/package. There are other types of tests, like integration or functional ones, that are not specifically part of the TDD methodology, strictly speaking, even though the TDD approach can be extended to any testing activity.

## A real-life example

Let's start with a simple example taken from a programmer's everyday life.

The programmer is in the office with other colleagues, trying to nail down an issue in some part of the software. Suddenly the boss storms into the office, and addresses the programmer:

**Boss**: I just met with the rest of the board. Our clients are not happy, we didn't fix enough bugs in the last two months.
**Programmer**: I see. How many bugs did we fix?
**Boss**: Well, not enough!
**Programmer**: OK, so how many bugs do we have to fix every month?
**Boss**: More!

I guess you feel very sorry for the poor programmer. Apart from the aggressive attitude of the boss, what is the real issue in this conversation? At the end of it there is no hint for the programmer and their colleagues about what to do next. They don't have any clue about what they have to change. They can definitely try to work harder, but the boss didn't refer to actual figures, so it will be definitely hard for the developers to understand if they improved "enough".

The classical [sorites paradox](https://en.wikipedia.org/wiki/Sorites_paradox) may help to understand the issue. One of the standard formulations, taken from the Wikipedia page, is

A> 1,000,000 grains of sand is a heap of sand (Premise 1)
A> A heap of sand minus one grain is still a heap. (Premise 2)
A> So 999,999 grains is a heap of sand.
A> A heap of sand minus one grain is still a heap. (Premise 2)
A> So 999,998 grains is a heap of sand.
A> ...
A> So one grain is a heap of sand.

Where is the issue? The concept expressed by the word "heap" is nebulous, it is not defined clearly enough to allow the process to find a stable point, or a solution.

When you write software you face that same challenge. You cannot conceive a function and just expect it "to work", because this is not clearly defined. How do you test if the function that you wrote "works"? What do you mean by "works"? TDD forces you to clearly state your goal before you write the code. Actually the TDD mantra is "Test first, code later", and we will shortly see a practical example of this.

For the time being, consider that this is a valid practice also outside the realm of software creation. Whoever runs a business knows that you need to be able to extract some numbers (KPIs) from the activity of your company, because it is by comparing those numbers with some predefined thresholds that you can easily tell if the business is healthy or not. KPIs are a form of test, and you have to define them in advance, according to the expectations or needs that you have. 

Pay attention. Nothing prevents you from changing the thresholds as a reaction to external events. You may consider that, given the incredible heat wave that hit your country, the amount of coats that your company sold could not reach the goal. So, because of a specific event, you can justify a change in the test (KPI). If you didn't have the test you would have just generically recorded that you earned less money.

Going back to software and TDD, following this methodology you are forced to state clear goals like

```
sum(4, 5) == 9
```

Let me read this test for you: there will be a `sum` function available in the system that accepts two integers. If the two integers are 4 and 5 the function will return 9.

As you can see there are many things that are tested by this statement.

* It tests that the function exists and can be imported
* It tests that the function accepts two integers
* It tests that giving 4 and 5 as inputs the output will be 9.

Pay attention that at this stage there is no code that implements the `sum` function, the tests will fail for sure.

As we will see with a practical example in the next chapter, what I explained in this section will become a set of rules of the methodology.

## A simple TDD project

The project we are going to develop is available at https://github.com/pycabook/calc

This project is purposefully extremely simple. You don't need to be an experienced Python programmer to follow this chapter, but you need to know the basics of the language. The goal of this chapter is not that of making you write the best Python code, but that of allowing you learn the TDD work flow, so don't be too worried if your code is not perfect.

Methodologies are like sports: you cannot learn them just by reading their description on a book. You have to practice them. Thus, you should avoid as much as possible to just follow this chapter reading the code passively. Instead, you should try to write the code and to try new solutions to the problems that I discuss. This is very important, as it actually makes you use TDD. This way, at the end of the chapter you will have a personal experience of what TDD is like.

## Setup the project

Following the instructions that you can find in the first chapter, create a virtual environment for the project, install Cookiecutter, and then create a project using the recommended template. I named the project `calc`, but you are free to give it another name. After you created the project, enter the directory and install the requirements with `pip install -r requirements/dev.txt`[^requirements]. You should be able to run

``` sh
$ py.test -svv
```

[^requirements]: this project template defines 3 different requirements files, `prod.txt`, `test.txt`, and `dev.txt`, in hierarchical order. `test.txt` includes `prod.txt`, and `dev.txt` includes `test.txt`. The reason is that when you test you want to be able to run the system with its production requirements, but you also need some tools to perform the tests, like the testing framework. When you develop, you want to test, but you also need tools to ease the development, like for example a linter or a version manager.

and get an output like

``` txt
=============================== test session starts ===============================
platform linux -- Python 3.6.7, pytest-4.0.1, py-1.7.0, pluggy-0.8.0 --
cabook/venv3/bin/python3
cachedir: .cache
rootdir: cabook/code/calc, inifile: pytest.ini
plugins: cov-2.6.0
collected 1 items 

tests/test_calc.py::test_content PASSED

============================ 1 passed in 0.01 seconds =============================
```

If you use a different template or create the project manually you may need to install pytest explicitly and to properly format the project structure. I strongly recommend to use the template if you are a beginner, as the proper setup can be tricky to achieve.

## Requirements

The goal of the project is to write a class `Calc` that performs calculations: addition, subtraction, multiplication, and division. Addition and multiplication shall accept multiple arguments. Division shall return a float value, and division by zero shall return the string `"inf"`. Multiplication by zero must raise a `ValueError` exception. The class will also provide a function to compute the average of an iterable like a list. This function gets two optional upper and lower thresholds and should remove from the computation the values that fall outside these boundaries.

As you can see the requirements are pretty simple, and a couple of them are definitely not "good" requirements, like the behaviour of division and multiplication. I added those requirements for the sake of example, to show how to deal with exceptions when developing in TDD.

## Step 1 - Adding two numbers

The first test we are going to write is one that checks if the `Calc` class can perform an addition. Remove the code in `tests/test_calc.py` (those functions are just templates for your tests) and insert this code

``` python
from calc.calc import Calc


def test_add_two_numbers():
    c = Calc()

    res = c.add(4, 5)

    assert res == 9
```

As you can see the first thing we do is to import the `Calc` class that we are supposed to write. This class doesn't exist yet, don't worry, you didn't skip any passage.

The test is a standard function (this is how pytest works). The function name shall begin with `test_` so that pytest can automatically discover all the tests. I tend to give my tests a descriptive name, so it is easier later to come back and understand what the test is about with a quick glance. You are free to follow the style you prefer but in general remember that naming components in a proper way is one of the most difficult things in programming. So better to get a handle on it as soon as possible.

The body of the test function is pretty simple. The `Calc` class is instantiated, and the `add` method of the instance is called with two numbers, 4 and 5. The result is stored in the `res` variable, which is later the subject of the test itself. The `assert res == 9` statement first computes `res == 9` which is a boolean statement, either `True` or `False`. The `assert` keyword, then, silently passes if the argument is `True`, but raises an exception if it is False.

And this is how pytest works: if your code doesn't raise any exception the test passes, otherwise it fails. `assert` is used to force an exception in case of wrong result. Remember that pytest doesn't consider the return value of the function, so it can detect a failure only if it raises an exception.

Save the file and go back to the terminal. Execute `py.test -svv` and you should receive the following error message

``` txt
===================================== ERRORS ======================================
_______________________ ERROR collecting tests/test_calc.py _______________________

[...]

tests/test_calc.py:4: in <module>
    from calc.calc import Calc
E   ImportError: cannot import name 'Calc'
!!!!!!!!!!!!!!!!!!!!! Interrupted: 1 errors during collection !!!!!!!!!!!!!!!!!!!!!
============================= 1 error in 0.20 seconds =============================
```

No surprise here, actually, as we just tried to use something that doesn't exist. This is good, the test is showing us that something we suppose exists actually doesn't.

{icon: graduation-cap}
B> **TDD rule number 1**
B> Test first, code later

This, by the way, is not yet an error in a test. The error happens very soon, during the tests collection phase (as shown by the message in the bottom line `Interrupted: 1 errors during collection`). Given this, the methodology is still valid, as we wrote a test and it fails because an error or a missing feature in the code.

Let's fix this issue. Open the `calc/calc.py` file and add write this code

``` python
class Calc:
    pass
```

But, I hear you scream, this class doesn't implement any of the requirements that are in the project. Yes, this is the hardest lesson you have to learn when you start using TDD. The development is ruled by the tests, not by the requirements. The requirements are used to write the tests, the tests are used to write the code. You shouldn't worry about something that is more than one level above the current one.

{icon: graduation-cap}
B> **TDD rule number 2**
B> Add the reasonably minimum amount of code you need to pass the tests

Run the test again, and this time you should receive a different error, that is

``` txt
=============================== test session starts ===============================
platform linux -- Python 3.6.7, pytest-4.0.1, py-1.7.0, pluggy-0.8.0 --
cabook/venv3/bin/python3
cachedir: .cache
rootdir: cabook/code/calc, inifile: pytest.ini
plugins: cov-2.6.0
collected 1 items 

tests/test_calc.py::test_add_two_numbers FAILED

==================================== FAILURES =====================================
______________________________ test_add_two_numbers _______________________________

    def test_add_two_numbers():
        c = Calc()
    
>       res = c.add(4, 5)
E       AttributeError: 'Calc' object has no attribute 'add'

tests/test_calc.py:7: AttributeError
============================ 1 failed in 0.04 seconds =============================
```

Since the last one is the first proper pytest failure report that we meet, it's time to learn how to read them. The first lines show you general information about the system where the tests are run

``` txt
=============================== test session starts ===============================
platform linux -- Python 3.6.7, pytest-4.0.1, py-1.7.0, pluggy-0.8.0 --
cabook/venv3/bin/python3
cachedir: .cache
rootdir: cabook/code/calc, inifile: pytest.ini
plugins: cov-2.6.0
```

In this case you can see that I'm using `linux` and get a quick list of the versions of the main packages involved in running pytest: Python, pytest itself, `py` (https://py.readthedocs.io/en/latest/) and `pluggy` (https://pluggy.readthedocs.io/en/latest/). You can also see here where pytest is reading its configuration from (`pytest.ini`), and the pytest plugins that are installed.

The second part of the output shows the list of files containing tests and the result of each test

``` txt
collected 1 items 

tests/test_calc.py::test_add_two_numbers FAILED
```

This list is formatted with a syntax that can be given directly to pytest to run a single test. In this case we already have only one test, but later you might run a single failing test giving the name shown here on the command line, like for example

``` sh
pytest -svv tests/test_calc.py::test_add_two_numbers
```

The third part shows details on the failing tests, if any.

``` txt
______________________________ test_add_two_numbers _______________________________

    def test_add_two_numbers():
        c = Calc()
    
>       res = c.add(4, 5)
E       AttributeError: 'Calc' object has no attribute 'add'

tests/test_calc.py:7: AttributeError
```

For each failing test, pytest shows a header with the name of the test and the part of the code that raised the exception. The last line of each of these boxes shows at which line of the test file the error happened.

Let's go back to the `Calc` project. Again, the new error is no surprise, as the test uses the `add` method that wasn't defined in the class. I bet you already guessed what I'm going to do, didn't you? This is the code that you should add to the class

``` python
class Calc:
    def add(self):
        pass
```

And again, as you notice, we made the smallest possible addition to the code to pass the test. Running this latter again the error message will be

```
_______________________________ test_add_two_numbers _______________________________

    def test_add_two_numbers():
        c = Calc()
    
>       res = c.add(4, 5)
E       TypeError: add() takes 1 positional argument but 3 were given

tests/test_calc.py:7: TypeError
```

(Through the rest of the chapter I will only show the error part of the failure report).

The function we defined doesn't accept any argument other than `self` (`def add(self)`), but in the test we pass three of them (`c.add(4, 5)`, remember that in Python `self` is implicit). Our move at this point is to change the function to accept the parameters that it is supposed to receive, namely two numbers. The code now becomes

``` python
class Calc:
    def add(self, a, b):
        pass
```

Run the test again, and you will receive another error

```
______________________________ test_add_two_numbers ________________________________

    def test_add_two_numbers():
        c = Calc()
    
        res = c.add(4, 5)
    
>       assert res == 9
E       assert None == 9

tests/test_calc.py:9: AssertionError
```

The function returns `None` as it doesn't contain any code, while the test expects it to return `9`. What do you think is the minimum code you can add to pass this test?

Well, the answer is

``` python
class Calc:
    def add(self, a, b):
        return 9
```

and this may surprise you (it should!). You might have been tempted to add some code that performs an addition between `a` and `b`, but this would violate the TDD principle, because you would have been driven by the requirements and not by the tests.

I know this sound weird, but think about it: if your code works, for now you don't need anything more complex than this. Maybe in the future you will discover that this solution is not good enough, and at that point you will have to change it (this will happen with the next test, in this case). But for now everything works and you shouldn't implement more than this.

Run again the test suite to check that no tests fail, after which you can move on to the second step.

{icon: github}
B> Git tag: [step-1-adding-two-numbers](https://github.com/pycabook/calc/tree/step-1-adding-two-numbers)

## Step 2 - Adding three numbers

The requirements state that "Addition and multiplication shall accept multiple arguments". This means that we should be able to execute not only `add(4, 5)` like we did, but also `add(4, 5, 11)`, `add(4, 5, 11, 2)`, and so on. We can start testing this behaviour with the following test, that you should put in `tests/test_calc.py`, after the previous test that we wrote.

``` python
def test_add_three_numbers():
    c = Calc()

    res = c.add(4, 5, 6)

    assert res == 15
```

This test fails when we run the test suite

``` txt
_____________________________ test_add_three_numbers _______________________________

    def test_add_three_numbers():
>       assert Calc().add(4, 5, 6) == 15
E       TypeError: add() takes 3 positional arguments but 4 were given

tests/test_calc.py:15: TypeError
```

for the obvious reason that the function we wrote in the previous section accepts only 2 arguments other than `self`. What is the minimum code that you can write to fix this test?

Well, the simplest solution is to add another argument, so my first attempt is

``` python
class Calc:
    def add(self, a, b, c):
        return 9
```

which solves the previous error, but creates a new one. If that wasn't enough, it also makes the first test fail!

``` txt
______________________________ test_add_two_numbers ________________________________

    def test_add_two_numbers():
        c = Calc()
    
>       res = c.add(4, 5)
E       TypeError: add() missing 1 required positional argument: 'c'

tests/test_calc.py:7: TypeError
_____________________________ test_add_three_numbers _______________________________

    def test_add_three_numbers():
        c = Calc()
    
        res = c.add(4, 5, 6)
    
>       assert res == 15
E       assert 9 == 15

tests/test_calc.py:17: AssertionError
```

The first test now fails because the new `add` method requires three arguments and we are passing only two. The second tests fails because the `add` method returns `9` and not `15` as expected by the test.

When multiple tests fail it's easy to feel discomforted and lost. Where are you supposed to start fixing this? Well, one possible solution is to undo the previous change and to try a different solution, but in general you should try to get to a situation in which only one test fails.

{icon: graduation-cap}
B> **TDD rule number 3**
B> You shouldn't have more than one failing test at a time

This is very important as it allows you to focus on one single test and thus one single problem. And remember, commenting tests to make them inactive is a perfectly valid way to have only one failing test. In this case I will comment the second test, so my tests file is now

``` python
from calc.calc import Calc


def test_add_two_numbers():
    c = Calc()

    res = c.add(4, 5)

    assert res == 9


## def test_add_three_numbers():
##     c = Calc()

##     res = c.add(4, 5, 6)

##     assert res == 15
```

And running the test suite returns only one failure

``` txt
______________________________ test_add_two_numbers ________________________________

    def test_add_two_numbers():
        c = Calc()
    
>       res = c.add(4, 5)
E       TypeError: add() missing 1 required positional argument: 'c'

tests/test_calc.py:7: TypeError
```

To fix this error we can obviously revert the addition of the third argument, but this would mean going back to the previous solution. Obviously, though tests focus on a very small part of the code, we have to keep in mind what we are doing in terms of the big picture. A better solution is to add to the third argument a default value. The additive identity is `0`, so the new code of the `add` method is

``` python
class Calc:
    def add(self, a, b, c=0):
        return 9
```

And this makes the failing test pass. At this point we can uncomment the second test and see what happens.

``` txt
_____________________________ test_add_three_numbers ______________________________

    def test_add_three_numbers():
        c = Calc()
    
        res = c.add(4, 5, 6)
    
>       assert res == 15
E       assert 9 == 15

tests/test_calc.py:17: AssertionError
```

The test suite fails, because the returned value is still not correct for the second test. At this point the tests show that our previous solution (`return 9`) is not sufficient anymore, and we have to try to implement something more complex.

We know that writing `return 15` will make the first test fail (you may try, if you want), so here we have to be a bit smarter and try a better solution, that in this case is actually to implement a real sum

``` python
class Calc:
    def add(self, a, b, c=0):
        return a + b + c
```

This solution makes both tests pass, so the entire suite runs without errors.

{icon: github}
B> Git tag: [step-2-adding-three-numbers](https://github.com/pycabook/calc/tree/step-2-adding-three-numbers)

I can see your face, your are probably frowning at the fact that it took us 10 minutes to write a method that performs the addition of two or three numbers. On the one hand, keep in mind that I'm going at a very slow pace, this being an introduction, and for these first tests it is better to take the time to properly understand every single step. Later, when you will be used to TDD, some of these steps will be implicit. On the other hand, TDD _is_ slower than untested development, but the time that you invest writing tests now is usually nothing compared to the amount of time you might spend trying to indentify and fix bugs later.

## Step 3 - Adding multiple numbers

The requirements are not yet satisfied, however, as they mention "multiple" numbers and not just three. How can we test that we can add a generic amount of numbers? We might add a `test_add_four_numbers`, a `test_add_five_numbers`, and so on, but this will cover specific cases and will never cover all of them. Sad to say, it is impossible to test that generic condition, or, at least in this case, so complex that it is not worth trying to do it.

What you shall do in TDD is to test boundary cases. In general you should always try to find the so-called "corner cases" of your algorithm and write tests that show that the code covers them. For example, if you are testing some code that accepts inputs from 1 to 100, you need a test that runs it with a generic number like 42[^42], but you definitely want to have a specific test that runs the algorithm with the number 1 and one that runs with the number 100. You also want to have tests that show the algorithm doesn't work with 0 and 101 arguments, but we will talk later about testing error conditions.

[^42]: which is far from being generic, but don't panic!

In our example there is no real limitation to the number of arguments that you pass to your function. Before Python 3.7 there was a limit of 256 arguments, which has been removed in that version of the language, but these are limitations enforced by an external system[^external], and they are not real boundaries of your algorithm.

[^external]: the definition of "external system" obviously depends on what you are testing. If you are implementing a programming language you want to have tests that show how many arguments you can pass to a function, or that check the amount of memory used by certain language features. In this case we accept the Python language as the environment in which we work, so we don't want to test its features.

The solution, in this case, might be to test a reasonable high amount of input arguments, to check that everything works. In particular, we should have a concern for a generic solution, which cannot rely on default arguments. To be clear, we easily realise that we cannot come up with a function like

``` python
    def add(self, a, b, c=0, d=0, e=0, f=0, g=0, h=0, i=0):
```

as it is not "generic", it is just covering a greater amount of inputs (9, in this case, but not 10 or more).

That said, a good test might be the following

``` python
def test_add_many_numbers():
    s = range(100)

    assert Calc().add(*s) == 4950
```

which creates an array[^iterable] of all the numbers from 0 to 99. The sum of all those numbers is 4950, which is what the algorithm shall return. The test suite fails because we are giving the function too many arguments

[^iterable]: strictly speaking this creates a `range`, which is an iterable.

``` txt
______________________________ test_add_many_numbers _______________________________

    def test_add_many_numbers():
        s = range(100)
    
>       assert Calc().add(*s) == 4950
E       TypeError: add() takes from 3 to 4 positional arguments but 101 were given

tests/test_calc.py:23: TypeError
```

The minimum amount of code that we can add, this time, will not be so trivial, as we have to pass three tests. Fortunately the tests that we wrote are still there and will check that the previous conditions are still satisfied.

The way Python provides support to a generic number of arguments (technically called "variadic functions") is through the use of the `*args` syntax, which stores in `args` a tuple that contains all the arguments.

``` python
class Calc:
    def add(self, *args):
        return sum(args)
```

At that point we can use the `sum` built-in function to sum all the arguments. This solution makes the whole test suite pass without errors, so it is correct.

{icon: github}
B> Git tag: [step-3-adding-multiple-numbers](https://github.com/pycabook/calc/tree/step-3-adding-multiple-numbers)

Pay attention here, please. In TDD a solution is not correct when it is beautiful, when it is smart, or when it uses the latest feature of the language. All these things are good, but TDD wants your code to pass the tests. So, your code might be ugly, convoluted, and slow, but if it passes the test it is correct. This in turn means that TDD doesn't cover all the needs of your software project. Delivering fast routines, for example, might be part of the advantage you have on your competitors, but it is not really testable with the TDD methodology[^testit].

[^testit]: yes, you can test it running a function and measuring the execution time. This however, depends too much on external conditions, so typically performance testing is done in a completely different way.

Part of the TDD methodology, then, deals with "refactoring", which means changing the code in a way that doesn't change the outputs, which in turns means that all your tests keep passing. Once you have a proper test suite in place, you can focus on the beauty of the code, or you can introduce smart solutions according to what the language allows you to do.

{icon: graduation-cap}
B> **TDD rule number 4**
B> Write code that passes the test. Then refactor it.

## Step 4 - Subtraction

From the requirements we know that we have to implement a function to subtract numbers, but this doesn't mention multiple arguments (as it would be complex to define what subtracting 3 of more numbers actually means). The tests that implements this requirements is

``` python
def test_subtract_two_numbers():
    c = Calc()

    res = c.sub(10, 3)

    assert res == 7
```

which doesn't pass with the following error

``` txt
____________________________ test_subtract_two_numbers ____________________________

    def test_subtract_two_numbers():
        c = Calc()
    
>       res = c.sub(10, 3)
E       AttributeError: 'Calc' object has no attribute 'sub'

tests/test_calc.py:29: AttributeError
```

Now that you understood the TDD process, and that you know you should avoid over-engineering, you can also skip some of the passages that we run through in the previous sections. A good solution for this test is

``` python
    def sub(self, a, b):
        return a - b
```

which makes the test suite pass.

{icon: github}
B> Git tag: [step-4-subtraction](https://github.com/pycabook/calc/tree/step-4-subtraction)

## Step 5 - Multiplication

It's time to move to multiplication, which has many similarities to addition. The requirements state that we have to provide a function to multiply numbers and that this function shall allow us to multiply multiple arguments. In TDD you should try to tackle problems one by one, possibly dividing a bigger requirement in multiple smaller ones.

In this case the first test can be the multiplication of two numbers, as it was for addition.

``` python
def test_mul_two_numbers():
    c = Calc()

    res = c.mul(6, 4)

    assert res == 24
```

And the test suite fails as expected with the following error

``` txt
______________________________ test_mul_two_numbers _______________________________
                                                                                                                                                                        
    def test_mul_two_numbers():
        c = Calc()

>       res = c.mul(6, 4)                                                 
E       AttributeError: 'Calc' object has no attribute 'mul'

tests/test_calc.py:37: AttributeError
```

We face now a classical TDD dilemma. Shall we implement the solution to this test as a function that multiplies two numbers, knowing that the next test will invalidate it, or shall we already consider that the target is that of implementing a variadic function and thus use `*args` directly?

In this case the choice is not really important, as we are dealing with very simple functions. In other cases, however, it might be worth recognising that we are facing the same issue we solved in a similar case and try to implement a smarter solution from the very beginning. In general, however, you should not implement anything that you don't plan to test in one of the next two tests that you will write.

If we decide to follow the strict TDD, that is implement the simplest first solution, the bare minimum code that passes the test would be

``` python
    def mul(self, a, b):
        return a * b
```

{icon: github}
B> Git tag: [step-5-multiply-two-numbers](https://github.com/pycabook/calc/tree/step-5-multiply-two-numbers)

To show you how to deal with redundant tests I will in this case choose the second path, and implement a smarter solution for the present test. Keep in mind however that it is perfectly correct to implement that solution shown above and then move on and try to solve the problem of multiple arguments later.

The problem of multiplying a tuple of numbers can be solved in Python using the `reduce` function. This function implements a typical algorithm that "reduces" an array to a single number, applying a given function. The algorithm steps are the following

1. Apply the function to the first two elements
2. Remove the first two elements from the array
3. Apply the function to the result of the previous step and to the first element of the array
4. Remove the first element
5. If there are still elements in the array go back to step 3

So, suppose the function is

``` python
def mul2(a, b):
    return a * b
```

and the array is

``` python
a = [2, 6, 4, 8, 3]
```

The steps followed by the algorithm will be

1. Apply the function to 2 and 6 (first two elements). The result is `2 * 6`, that is 12
2. Remove the first two elements, the array is now `a = [4, 8, 3]`
3. Apply the function to 12 (result of the previous step) and 4 (first element of the array). The new result is `12 * 4`, that is 48
4. Remove the first element, the array is now `a = [8, 3]`
5. Apply the function to 48 (result of the previous step) and 8 (first element of the array). The new result is `48 * 8`, that is 384
6. Remove the first element, the array is now `a = [3]`
7. Apply the function to 384 (result of the previous step) and 3 (first element of the array). The new result is `384 * 3`, that is 1152
8. Remove the first element, the array is now empty and the procedure ends

Going back to our `Calc` class, we might import `reduce`[^reduce] form the `functools` module and use it on the `args` array. We need to provide a function that we can define in the `mul` function itself.

``` python
from functools import reduce


class Calc:
    [...]

    def mul(self, *args):
        def mul2(a, b):
            return a * b

        return reduce(mul2, args)
```

{icon: github}
B> Git tag: [step-5-multiply-two-numbers-smart](https://github.com/pycabook/calc/tree/step-5-multiply-two-numbers-smart)

[^reduce]: More information about the `reduce` algorithm can be found on the MapReduce Wikipedia page [https://en.wikipedia.org/wiki/MapReduce](https://en.wikipedia.org/wiki/MapReduce). The Python function documentation can be found at [https://docs.python.org/3.6/library/functools.html#functools.reduce](https://docs.python.org/3.6/library/functools.html#functools.reduce).

The above code makes the test suite pass, so we can move on and address the next problem. As happened with addition we cannot properly test that the function accepts a potentially infinite number of arguments, so we can test a reasonably high number of inputs.

``` python
def test_mul_many_numbers():
    s = range(1, 10)

    assert Calc().mul(*s) == 362880
```

{icon: github}
B> Git tag: [step-5-multiply-many-numbers](https://github.com/pycabook/calc/tree/step-5-multiply-many-numbers)

We might use 100 arguments as we did with addition, but the multiplication of all numbers from 1 to 100 gives a result with 156 digits and I don't really need to clutter the tests file with such a monstrosity. As I said, testing multiple arguments is testing a boundary, and the idea is that if the algorithm works for 2 numbers and for 10 it will work for 10 thousands arguments as well.

If we run the test suite now all tests pass, and this should worry you.

Yes, you shouldn't be happy. When you follow TDD each new test that you add should fail. If it doesn't fail you should ask yourself if it is worth adding that test or not. This is because chances are that you are adding a useless test and we don't want to add useless code, because code has to be maintained, so the less the better.

In this case, however, we know why the test already passes. We implemented a smarter algorithm as a solution for the first test knowing that we would end up trying to solve a more generic problem. And the value of this new test is that it shows that multiple arguments can be used, while the first test doesn't.

So, after this considerations, we can be happy that the second test already passes.

{icon: graduation-cap}
B> **TDD rule number 5**
B> A test should fail the first time you run it. If it doesn't, ask yourself why you are adding it.

## Step 6 - Refactoring

Previously, I introduced the concept of refactoring, which means changing the code without altering the results. How can you be sure you are not altering the behaviour of your code? Well, this is what the tests are for. If the new code keeps passing the test suite you can be sure that you didn't remove any feature[^refactoring].

[^refactoring]: In theory, refactoring shouldn't add any new behaviour to the code, as it should be an idempotent transformation. There is no real practical way to check this, and we will not bother with it now. You should be concerned with this if you are discussing security, as your code shouldn't add any entry point you don't want to be there. In this case you will need tests that check not the presence of some feature, but the absence of them.

This means that if you have no tests you shouldn't refactor. But, after all, if you have no tests you shouldn't have any code, either, so refactoring shouldn't be a problem you have. If you have some code without tests (I know you have it, I do), you should seriously consider writing tests for it, at least before changing it. More on this in a later section.

For the time being, let's see if we can work on the code of the `Calc` class without altering the results. I do not really like the definition of the `mul2` function inside the `mul` one. It is obviously perfectly fine and valid, but for the sake of example I will pretend we have to get rid of it.

Python provides support for anonymous functions with the `lambda` operator, so I might replace the `mul` code with

``` python
from functools import reduce


class Calc:
    [...]

    def mul(self, *args):
        return reduce(lambda x, y: x*y, args)
```

{icon: github}
B> Git tag: [step-6-refactoring](https://github.com/pycabook/calc/tree/step-6-refactoring)

where I define an anonymous function that accepts two inputs `x, y` and returns their multiplication `x*y`. Running the test suite I can see that all the test pass, so my refactoring is correct.

{icon: graduation-cap}
B> **TDD rule number 6**
B> Never refactor without tests.

## Step 7 - Division

The requirements state that there shall be a division function, and that it has to return a float value. This is a simple condition to test, as it is sufficient to divide two numbers that do not give an integer result

``` python
def test_div_two_numbers_float():
    c = Calc()

    res = c.div(13, 2)

    assert res == 6.5
```

The test suite fails with the usual error that signals a missing method. The implementation of this function is very simple as the `/` operator in Python performs a float division

``` python
class Calc:
    [...]

    def div(self, a, b):
        return a / b
```

{icon: github}
B> Git tag: [step-7-float-division](https://github.com/pycabook/calc/tree/step-7-float-division)

If you run the test suite again all the test should pass. There is a second requirement about this operation, however, that states that division by zero shall return the string `"inf"`. Now, this is obviously a requirement that I introduced for the sake of giving some interesting and simple problem to solve with TDD, as an API that returns either floats or strings is not really the best idea.

The test that comes from the requirement is simple

``` python
def test_div_by_zero_returns_inf():
    c = Calc()

    res = c.div(5, 0)

    assert res == "inf"
```

And the test suite fails now with this message

``` txt
__________________________ test_div_by_zero_returns_inf ___________________________

    def test_div_by_zero_returns_inf():
        c = Calc()
    
>       res = c.div(5, 0)

tests/test_calc.py:59: 
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

self = <calc.calc.Calc object at 0x7f56c3dddb70>, a = 5, b = 0

    def div(self, a, b):
>       return a / b
E       ZeroDivisionError: division by zero

calc/calc.py:15: ZeroDivisionError
```

Note that when an exception happens in the code and not in the test, the pytest output changes slightly. The first part of the message shows where the test fails, but then there is a second part that shows the internal code that raised the exception and provides information about the value of local variables on the first line (`self = <calc.calc.Calc object at 0x7f56c3dddb70>, a = 5, b = 0`).

We might implement two different solutions to satisfy this requirement and its test. The first one is to prevent `b` to be 0

``` python
    def div(self, a, b):
        if not b:
            return "inf"

        return a / b
```

and the second one is to intercept the exception with a `try/except` block

``` python
    def div(self, a, b):
        try:
            return a / b
        except ZeroDivisionError:
            return "inf"
```

Both solutions make the test suite pass, so both are correct. I leave to you the decision about which is the best one, syntactically speaking.

{icon: github}
B> Git tag: [step-7-division-by-zero](https://github.com/pycabook/calc/tree/step-7-division-by-zero)

## Step 8 - Testing exceptions

A further requirement is that multiplication by zero must raise a `ValueError` exception. This means that we need a way to test if our code raises an exception, which is the opposite of what we did until now. In the previous tests, the condition to pass was that there was no exception in the code, while in this test the condition will be that an exception has been raised.

Pytest provides a `raises` context manager that runs the code contained in it and passes only if the given exception is produced by that code.

``` python
import pytest

[...]

def test_mul_by_zero_raises_exception():
    c = Calc()

    with pytest.raises(ValueError):
        c.mul(3, 0)
```

In this case, thus, pytest runs the line `c.mul(3, 0)`. If it doesn't raise the `ValueError` exception the test will fail. Indeed, if you run the test suite now, you will get the following failure

``` txt
________________________ test_mul_by_zero_raises_exception ________________________

    def test_mul_by_zero_raises_exception():
        c = Calc()
    
        with pytest.raises(ValueError):
>           c.mul(3, 0)
E           Failed: DID NOT RAISE <class 'ValueError'>

tests/test_calc.py:70: Failed
```

which explicitly signals that the code didn't raise the expected exception.

The code that makes the test pass needs to test if one of the inputs of the `mul` functions is 0. This can be done with the help of the built-in `all` Python function, which accepts an iterable and returns `True` only if all the values contained in it are `True`. Since in Python the value `0` is not true, we may write

``` python
    def mul(self, *args):
        if not all(args):
            raise ValueError
        return reduce(lambda x, y: x*y, args)
```

and make the test suite pass. The if condition checks that there are no false values in the `args` tuples, that is there are no zeros.

{icon: github}
B> Git tag: [step-8-multiply-by-zero](https://github.com/pycabook/calc/tree/step-8-multiply-by-zero)

## Step 9 - A more complex set of requirements

Until now the requirements were pretty simple, so it's time to try to tackle a more complex problem. The remaining requirements say that the class has to provide a function to compute the average of an iterable, and that this function shall accept two optional upper and lower thresholds to remove outliers.

Let's break this two requirements into a set of simpler ones

1. The function accepts an iterable and computes the average, i.e. `avg([2, 5, 12, 98]) == 29.25`
2. The function accepts an optional upper threshold. It must remove all the values that are greater than the threshold before computing the average, i.e. `avg([2, 5, 12, 98], ut=90) == avg([2, 5, 12])`
3. The function accepts an optional lower threshold. It must remove all the values that are less then the threshold before computing the average, i.e. `avg([2, 5, 12, 98], lt=10) == avg([12, 98])`
4. The upper threshold is not included in the comparison, i.e. `avg([2, 5, 12, 98], ut=98) == avg([2, 5, 12, 98])`
5. The lower threshold is not included in the comparison, i.e. `avg([2, 5, 12, 98], ut=5) == avg([5, 12, 98])`
6. The function works with an empty list, returning `0`, i.e. `avg([]) == 0`
7. The function works if the list is empty after outlier removal, i.e. `avg([12, 98], lt=15, ut=90) == 0`
8. The function outlier removal works if the list is empty, i.e. `avg([], lt=15, ut=90) == 0`

As you can see a simple requirement can produce multiple tests. Some of these are clearly expressed by the requirement (numbers 1, 2, 3), some of these are choices that we make (numbers 4, 5, 6) and can be discussed, some are boundary cases that we have to discover thinking about the problem (numbers 6, 7, 8).

There is a fourth category of tests, which are the ones that come from bugs that you discover. We will discuss about those later in this chapter.

### Step 9.1 - Average of an iterable

Let's start adding a test for requirement number 1

``` python
def test_avg_correct_average():
    c = Calc()

    res = c.avg([2, 5, 12, 98])

    assert res == 29.25
```

We feed the `avg` function a list of generic numbers, which average we calculated with an external tool. The first run of the test suite fails with the usual complaint about a missing function

``` txt
____________________________ test_avg_correct_average _____________________________

    def test_avg_correct_average():
        c = Calc()
    
>       res = c.avg([2, 5, 12, 98])
E       AttributeError: 'Calc' object has no attribute 'avg'

tests/test_calc.py:76: AttributeError
```

And we can make the test pass with a simple use of `sum` and `len`, as both built-in functions work on iterables

``` python
class Calc:
    [...]

    def avg(self, it):
        return sum(it)/len(it)
```

{icon: github}
B> Git tag: [step-9-1-average-of-an-iterable](https://github.com/pycabook/calc/tree/step-9-1-average-of-an-iterable)

### Step 9.2 - Upper threshold

The second requirement mentions an upper threshold, but we are free with regards to the API, i.e. the requirement doesn't specify how the threshold is supposed to be specified or named. I decided to call the upper threshold parameter `ut`, so the test becomes

``` python
def test_avg_removes_upper_outliers():
    c = Calc()

    res = c.avg([2, 5, 12, 98], ut=90)

    assert res == pytest.approx(6.333333)
```

As you can see the `ut=90` parameter is supposed to remove the element `98` from the list and then compute the average of the remaining elements. Since the result has an infinite number of digits I used the `pytest.approx` function to check the result.

The test suite fails because the `avg` function doesn't accept the `ut` parameter

``` txt
_________________________ test_avg_removes_upper_outliers _________________________

    def test_avg_removes_upper_outliers():
        c = Calc()
    
>       res = c.avg([2, 5, 12, 98], ut=90)
E       TypeError: avg() got an unexpected keyword argument 'ut'

tests/test_calc.py:84: TypeError
```

There are two problems now that we have to solve, as it happened for the second test we wrote in this project. The new `ut` argument needs a default value, so we have to manage that case, and then we have to make the upper threshold work. My solution is

``` python
    def avg(self, it, ut=None):
        if not ut:
            ut = max(it)

        _it = [x for x in it if x <= ut]

        return sum(_it)/len(_it)
```

The idea here is that `ut` is used to filter the iterable keeping all the elements that are less than or equal to the threshold. This means that the default value for the threshold has to be neutral with regards to this filtering operation. Using the maximum value of the iterable makes the whole algorithm work in every case, while for example using a big fixed value like `9999` would introduce a bug, as one of the elements of the iterable might be bigger than that value.

{icon: github}
B> Git tag: [step-9-2-upper-threshold](https://github.com/pycabook/calc/tree/step-9-2-upper-threshold)

### Step 9.3 - Lower threshold

The lower threshold is the mirror of the upper threshold, so it doesn't require many explanations. The test is

``` python
def test_avg_removes_lower_outliers():
    c = Calc()

    res = c.avg([2, 5, 12, 98], lt=10)

    assert res == pytest.approx(55)
```

and the code of the `avg` function now becomes

``` python
    def avg(self, it, lt=None, ut=None):
        if not lt:
            lt = min(it)

        if not ut:
            ut = max(it)

        _it = [x for x in it if x >= lt and x <= ut]

        return sum(_it)/len(_it)
```

{icon: github}
B> Git tag: [step-9-3-lower-threshold](https://github.com/pycabook/calc/tree/step-9-3-lower-threshold)

### Step 9.4 and 9.5 - Boundary inclusion

As you can see from the code of the `avg` function, the upper and lower threshold are included in the comparison, so we might consider the requirements as already satisfied. TDD, however, pushes you to write a test for each requirement (as we saw it's not unusual to actually have multiple tests per requirements), and this is what we are going to do. 

The reason behind this is that you might get the expected behaviour for free, like in this case, because some other code that you wrote to pass a different test provides that feature as a side effect. You don't know, however what will happen to that code in the future, so if you don't have tests that show that all your requirements are satisfied you might lose features without knowing it.

The test for the fourth requirement is

``` python
def test_avg_uppper_threshold_is_included():
    c = Calc()

    res = c.avg([2, 5, 12, 98], ut=98)

    assert res == 29.25
```

{icon: github}
B> Git tag: [step-9-4-upper-threshold-is-included](https://github.com/pycabook/calc/tree/step-9-4-upper-threshold-is-included)

while the test for the fifth one is

``` python
def test_avg_lower_threshold_is_included():
    c = Calc()

    res = c.avg([2, 5, 12, 98], lt=2)

    assert res == 29.25
```

{icon: github}
B> Git tag: [step-9-5-lower-threshold-is-included](https://github.com/pycabook/calc/tree/step-9-5-lower-threshold-is-included)

And, as expected, both pass without any change in the code.

### Step 9.6 - Empty list

Requirement number 6 is something that wasn't clearly specified in the project description so we decided to return 0 as the average of an empty list. You are free to change the requirement and decide to raise an exception, for example.

The test that implements this requirement is

``` python
def test_avg_empty_list():
    c = Calc()

    res = c.avg([])

    assert res == 0
```

and the test suite fails with the following error

``` txt
_______________________________ test_avg_empty_list _______________________________

    def test_avg_empty_list():
        c = Calc()
    
>       res = c.avg([])

tests/test_calc.py:116: 
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

self = <calc.calc.Calc object at 0x7f732ce8f6d8>, it = [], lt = None, ut = None

    def avg(self, it, lt=None, ut=None):
        if not lt:
>           lt = min(it)
E           ValueError: min() arg is an empty sequence

calc/calc.py:24: ValueError
```

The `min` function that we used to compute the default lower threshold doesn't work with an empty list, so the code raises an exception. The simplest solution is to check for the length of the iterable before computing the default thresholds

``` python
    def avg(self, it, lt=None, ut=None):
        if not len(it):
            return 0

        if not lt:
            lt = min(it)

        if not ut:
            ut = max(it)

        _it = [x for x in it if x >= lt and x <= ut]

        return sum(_it)/len(_it)
```

{icon: github}
B> Git tag: [step-9-6-empty-list](https://github.com/pycabook/calc/tree/step-9-6-empty-list)

As you can see the `avg` function is already pretty rich, but at the same time it is well structured and understandable. This obviously happens because the example is trivial, but cleaner code is definitely among the benefits of TDD.

### Step 9.7 - Empty list after applying the thresholds

The next requirement deals with the case in which the outlier removal process empties the list. The test is the following

``` python
def test_avg_manages_empty_list_after_outlier_removal():
    c = Calc()

    res = c.avg([12, 98], lt=15, ut=90)

    assert res == 0
```

and the test suite fails with a `ZeroDivisionError`, because the length of the iterable is now 0.

``` txt
________________ test_avg_manages_empty_list_after_outlier_removal ________________

    def test_avg_manages_empty_list_after_outlier_removal():
        c = Calc()
    
>       res = c.avg([12, 98], lt=15, ut=90)

tests/test_calc.py:124: 
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

self = <calc.calc.Calc object at 0x7f6f687a0a58>, it = [12, 98], lt = 15, ut = 90

    def avg(self, it, lt=None, ut=None):
        if not len(it):
            return 0
    
        if not lt:
            lt = min(it)
    
        if not ut:
            ut = max(it)
    
        _it = [x for x in it if x >= lt and x <= ut]
    
>       return sum(_it)/len(_it)
E       ZeroDivisionError: division by zero

calc/calc.py:34: ZeroDivisionError
```

The easiest solution is to introduce a new check on the length of the iterable

``` python
    def avg(self, it, lt=None, ut=None):
        if not len(it):
            return 0

        if not lt:
            lt = min(it)

        if not ut:
            ut = max(it)

        _it = [x for x in it if x >= lt and x <= ut]

        if not len(_it):
            return 0

        return sum(_it)/len(_it)
```

And this code makes the test suite pass. As I stated before, code that makes the tests pass is considered correct, but you are always allowed to improve it. In this case I don't really like the repetition of the length check, so I might try to refactor the function to get a cleaner solution. Since I have all the tests that show that the requirements are satisfied, I am free to try to change the code of the function.

After some attempts I found this solution

``` python
    def avg(self, it, lt=None, ut=None):
        _it = it[:]

        if lt:
            _it = [x for x in _it if x >= lt]

        if ut:
            _it = [x for x in _it if x <= ut]

        if not len(_it):
            return 0

        return sum(_it)/len(_it)
```

which looks reasonably clean, and makes the whole test suite pass.

{icon: github}
B> Git tag: [step-9-7-empty-list-after-thresholds](https://github.com/pycabook/calc/tree/step-9-7-empty-list-after-thresholds)

### Step 9.8 - Empty list before applying the thresholds

The last requirement checks another boundary case, which happens when the list is empty and we specify one of or both the thresholds. This test will check that the outlier removal code doesn't assume the list contains elements.

``` python
def test_avg_manages_empty_list_before_outlier_removal():
    c = Calc()

    res = c.avg([], lt=15, ut=90)

    assert res == 0
```

This test doesn't fail. So, according to the TDD methodology, we should justify the reason why it doesn't fail, and decide if we want to keep it. The reason why it doesn't fail is because the two list comprehensions used to filter the elements work perfectly with empty lists. As for the test, it comes directly from a corner case, and it checks a behaviour which is not already covered by other tests. This makes me decide to keep the test.

{icon: github}
B> Git tag: [step-9-8-empty-list-before-thresholds](https://github.com/pycabook/calc/tree/step-9-8-empty-list-before-thresholds)

## Recap of the TDD rules

Through this very simple example we learned 6 important rules of the TDD methodology. Let us review them, now that we have some experience that can make the words meaningful

1. Test first, code later
2. Add the bare minimum amount of code you need to pass the tests
3. You shouldn't have more than one failing test at a time
4. Write code that passes the test. Then refactor it.
5. A test should fail the first time you run it. If it doesn't ask yourself why you are adding it.
6. Never refactor without tests.

## How many assertions?

I am frequently asked "How many assertions do you put in a test?", and I consider this question important enough to discuss it in a dedicated section. To answer this question I want to briefly go back to the nature of TDD and the role of the test suite that we run.

The whole point of automated tests is to run through a set of checkpoints that can quickly reveal that there is a problem in a specific area. Mind the words "quickly" and "specific". When I run the test suite and an error occurs I'd like to be able to understand as fast as possible where the problem lies. This doesn't (always) mean that the problem will have a quick resolution, but at least I can be immediately aware of which part of the system is misbehaving.

On the other side, we don't want to have too many test for the same condition, on the contrary we want to avoid testing the same condition more than once as tests have to be maintained. A test suite that is too fine-grained might result in too many tests failing because of the same problem in the code, which might be daunting and not very informative.

My advice is to group together assertions that can be done after the same setup, if they test the same process. For example, you might consider the two functions `add` and `sub` that we tested in this chapter. They require the same setup, which is to instantiate the `Calc` class (a setup that they share with many other tests), but they are actually testing two different processes. A good sign of this is that you should rename the test to `test_add_or_sub`, and a failure in this test would require a further investigation in the test output to check which method of the class is failing.

If you had to test that a method returns positive even numbers, instead, you might consider running the method and then writing two assertions, one that checks that the number is positive, and one that checks it is even. This makes sense, as a failure in one of the two means a failure of the whole process.

As a quick rule of thumb, then, consider if the test is a logical `AND` between conditions or a logical `OR`. In the former case go for multiple assertions, in the latter create multiple test functions.

## How to manage bugs or missing features

In this chapter we developed the project from scratch, so the challenge was to come up with a series of small tests starting from the requirements. At a certain point in the life of your project you will have a stable version in production[^production] and you will need to maintain it. This means that people will file bug reports and feature requests, and TDD gives you a clear strategy to deal with those.

[^production]: this expression has many definitions, but in general it means "used by someone other than you".

From the TDD point of view both a bug and a missing feature are a case not currently covered by a test, so I will refer to them collectively as bugs, but don't forget that I'm talking about the second ones as well. 

The first thing you need to do is to write tests that expose the bug. This way you can easily decide when the code that you wrote is correct or good enough. For example, let's assume that a user file an issue on the `Calc` project saying: "The `add` function doesn't work with negative numbers". You should definitely try to get a concrete example from the user that wrote the issue and some information about the execution environment (as it is always possible that the problem come from a different source, like for example an old version of a library your package relies on), but in the meanwhile you can come up with at least 3 tests: one that involves two negative numbers, one with a negative number as the first argument, and one with a negative numbers as the second argument.

You shouldn't write down all of them at once. Write the first test that you think might expose the issue and see if it fails. If it doesn't, discard it and write a new one. From the TDD point of view, if you don't have a failing test there is no bug, so you have to come up with at least one test that exposes the issue you are trying to solve.

At this point you can move on and try to change the code. Remember that you shouldn't have more than one failing test at a time, so start doing this as soon as you discover a test case that shows there is a problem in the code.

Once you reach a point where the test suite passes without errors stop and try to run the code in the environment where the bug was first discovered (for example sharing a branch with the user that created the ticket) and iterate the process.

# Chapter 2 - On unit testing

{icon: quote-right}
B> _Describe in single words, only the good things that come into your mind about your mother._
B> - Blade Runner (1982)

## Introduction

What I introduced in the previous chapter is commonly called "unit testing", since it focuses on testing a single and very small unit of code. As simple as it may seem, the TDD process has some caveats that are worth being discussed. In this chapter I discuss some aspects of TDD and unit testing that I consider extremely important.

## Tests should be fast

You should run your tests many times, potentially you should run them every time you save your code. Your tests are the watchdogs of your code, the dashboard warning lights that signal a correct status or some malfunction. This means that your testing suite should be _fast_. If you have to wait minutes for each execution to finish, chances are that you will end up running your tests only after some long coding session, which means that you are not using them as guides.

It's true however that some tests may be intrinsically slow, or that the test suite might be so big that running it would take an amount of time which makes continuous testing uncomfortable. In this case you should identify a subset of tests that run quickly and that can show you if something is not working properly, the so-called "smoke tests", and leave the rest of the suite for longer executions that you run less frequently. Typically, the library part of your project has tests that run very quickly, as testing functions does not require specific set-ups, while the user interface tests (be it a CLI or a GUI) are usually slower.

## Tests should be idempotent

_Idempotency_ in mathematics and computer science identifies processes that can be run multiple times without changing the status of the system. Since this latter doesn't change, the tests can be run in whichever order without changing their results. If a test interacts with an external system leaving it in a different state you will have random failures depending on the execution order.

The typical example is when you interact with the filesystem in your tests. A test may create a file and not remove it, and this makes another test fail because the file already exists, or because the directory is not empty. Whatever you do while interacting with external systems has to be reverted after the test. If you run your tests concurrently, however, even this precaution is not enough.

This poses a big problem, as interacting with external systems is definitely to be considered dangerous. Mocks, introduced in the next chapter, are a very good tool to deal with this aspect of testing.

## Tests should be isolated

In computer science _isolation_ means that a component shall not change its behaviour depending on something that happens externally. In particular it shouldn't be affected by the execution of other components in the system (spatial isolation) and by previous execution of the component itself (temporal isolation). Each test should run as much as possible in an isolated universe.

While this is easy to achieve for small components, like we did with the `Calc` class, it might be almost impossible to do in more complex cases. Whatever routine you will write that deals with time, for example, be it the current date or a time interval, you are faced with something that flows incessantly and that cannot be stopped or slowed down. This is also true in other cases, for example if you are testing a routine that accesses an external service like a website. If the website is not reachable the test will fail, but this failure comes from an external source, not from the code under test.

Mocks are again a good tool to enforce isolation in tests that need to communicate with external actors in the system.

## External systems

It is important to understand that the above definitions (idempotency, isolation) depend on the scope of the test. You should consider _external_ whatever part of the system is not directly involved in the test, even though you need to use it to run the test itself. You should also try to reduce the scope of the test as much as possible.

Let me give you an example. Consider a web application and imagine a test that check that a user can log in. The login process involves many layers: the user inputs the username and the password in a GUI and submits the form, the GUI communicates with the core of the application that finds the user in the DB and checks the password hash against the one stored there, then sends back a message that grants access to the user, and the GUI stores a cookie to keep the user logged in. Suppose now that the test fails. Where is the error? Is it in the query that retrieves the user from the DB? Or in the routine that hashes the password? Or is it just an issue in the connectivity between the application and the database?

As you can see there are too many possible points of failure. While this is a perfectly valid _integration test_, it is definitely not a _unit test_. Unit tests try to test the smallest possible units of code in your system, usually simple routines like functions or object methods. Integration tests, instead, put together whole systems that have already been tested and test that they can work together.

Too many times developers confuse integration tests with unit tests. One simple example: every time a web framework makes you test your models against a real database you are mixing a unit test (the methods of the model object work) with an integration one (the model object connects with the database and can store/retrieve data). You have to learn how to properly identify what is external to your system in the scope of a given test, so your tests can be focused and small.

## Focus on messages

I will never recommend enough Sandi Metz's talk ["The Magic Tricks of Testing"](https://speakerdeck.com/skmetz/magic-tricks-of-testing-railsconf) where she considers the different messages that a software component has to deal with. She comes up with 3 different origins for messages (incoming, sent to self, and outgoing) and 2 types (query and command). The very interesting conclusion she reaches is that you should only test half of them, and I believe this is one of the most useful results you can learn as a software developer. In this section I will shamelessly start from Sandi Metz's categorisations and give a personal view of the matter. I absolutely recommend to watch the original talk as it is both short and very effective.

Testing is all about the behaviour of a component when it is used, i.e. when it is connected to other components that interact with it. This interaction is well represented by the word "message", which has hereafter the simple meaning of "data exchanged between two actors".

We can then classify the interactions happening in our system, and thus to our components, by flow[^flow] and by type.

[^flow]: Sandi Metz speaks of _origin_.

### Message flow

The flow is defined as the tuple `(source, origin)`, that is where the message comes from and what its destination is. There are three different combinations that we are interested in: `(outside, self)`, `(self, self)`, and `(self, outside)`, where `self` is the object we are testing, and `outside` is a generic object that lives in the system. There is a fourth combination, `(outside, outside)` that is not relevant for the testing, since it doesn't involve the object under analysis.

So `(outside, self)` contains all the messages that other parts of the system send to our component. These messages correspond to the public API of the component, that is the set of entry points the component makes available to interact with it. Notable examples are the public methods of an object in an object-oriented programming language or the HTTP endpoints of a Web application. This flow represents the _incoming messages_.

On the other side there is `(self, outside)`, which is the set of messages that the component under test sends to other parts of the system. These are for example the external calls that an object does to a library or to other objects, or the API of other applications we rely on, like databases or Web applications. This flow describes all the _outgoing messages_.

Between the two there is `(self, self)`, which identifies the messages that the component sends to itself, i.e. the use that the component does of its own internal API. This can be the set of private methods of an object or the business logic inside a Web application. The important thing about this last case is that while the component is seen as a black box by the rest of the system it actually has an internal structure and it uses it to run. This flow contains all the _private messages_.

### Message type

Messages can be further divided according to the interaction the source requires to have with the target: _queries_ and _commands_. Queries are messages that do not change the status of the component, they just extract information. The `Calc` class that we developed in the previous section is a typical example of object that exposes query methods. Adding two numbers doesn't change the status of the object, and you will receive the same answer every time you call the `add` method.

Commands, instead, are the complete opposite. They do not extract any information, but they change the status of the object. A method of an object that increases an internal counter or a method that adds values to an array are perfect examples of commands.

It's perfectly normal to combine a query and a command in a single message, as long as you are aware that your message is changing the status of the component. Remember that changing the status is something that can have concrete secondary effect.

## The testing grid

Combining 3 flows and 2 message types we get 6 different message cases that involve the component under testing. For each one of this cases we have to decide how to test the interaction represented by that flow and message type.

### Incoming queries

An incoming query is a message that an external actor sends to get a value from your component. Testing this behaviour is straightforward, as you just need to write a test that sends the message and makes an assertion on the returned value. A concrete example of this is what we did to test the `add` method of `Calc`.

### Incoming commands

And incoming command comes from an external actor that wants to change the status of the system. There should be a way for an external actor to check the status, which translates into the need of having either a companion incoming query message that allows to extract the status (or at least the part of the status affected by the command), or the knowledge that the change is going to affect the behaviour of another query. A simple example might be a method that sets the precision (number of digits) of the division in the `Calc` object. Setting that value changes the result of a query, which can be used to test the effect of the incoming command.

### Private queries

A private query is a message that the component sends to self to get a value without affecting its own state, and it is basically nothing more than an explicit use of some internal logic. This happens often in object-oriented languages because you extracted some common logic from one or more methods of an object and created a private method to avoid duplication.

Since private queries use the internal logic you shouldn't test them. This might be surprising, as private methods are code, and code should be tested, but remember that other methods are calling them, so the effects of that code are not invisible, they are tested by the tests of the public entry points, although indirectly. The only effect you would achieve by testing private methods is to lock the tests to the internal implementation of the component, which by definition shouldn't be used by anyone outside of the component itself. This in turn, makes refactoring painful, because you have to keep redundant tests in sync with the changes that you do, instead of using them as a guide for the code changes like TDD wants you to do.

As Sandi Metz says, however, this is not an inflexible rule. Whenever you see that testing an internal method makes the structure more robust feel free to do it. Be aware that you are locking the implementation, so do it only where it makes a real difference businesswise.

### Private commands

Private commands shouldn't be treated differently than private queries. They change the status of the component, but this is again part of the internal logic of the component itself, so you shouldn't test private commands either. As stated for private queries, feel free to do it if this makes a real difference.

### Outgoing queries and commands

An outgoing query is a message that the component under testing sends to an external actor asking for a value, without changing the status of the actor itself. The correctness of the returned value, given the inputs, is not part of what you want to test, because that is an incoming query for the external actor. Let me repeat this: you don't want to test that the external actor return the correct value given some inputs.

This is perhaps one of the biggest mistakes that programmers make when they test their applications. Definitely it is a mistake that I made many times. We tend to introduce tests that, starting from the code of our component, end up testing different components.

Outgoing commands are messages sent to external actors in order to change their state. Since our component sends such messages to cause an effect in another part of the system we have to be sure that the sent values are correct. We do not want to test that the state of the external actor change accordingly, as this is part of the testing suite of the external actor itself (incoming command).

From this consideration it is evident that you shouldn't test the results of any outgoing query or command. Possibly, you should avoid running them at all, otherwise you will need the external system to be up and running when you run the test suite.

We want to be sure, however, that our component uses the API of the external actor in a proper way and the standard technique to test this is to use mocks, that is components that simulate other components. Mocks are an important tool in the TDD methodology and for this reason they are the topic of the next chapter.

|Flow    |Type   |Test?|
|--------|-------|-----|
|Incoming|Query  |Yes  |
|Incoming|Command|Yes  |
|Private |Query  |Maybe|
|Private |Command|Maybe|
|Outgoing|Query  |Mock |
|Outgoing|Command|Mock |

## Conclusions

Since the discovery of TDD few thing changed the way I write code more than these considerations on what I am supposed to test. Out of 6 different type of tests we discovered that 2 shouldn't be tested, 2 of them require a very simple technique based on assertions, and the last 2 are the only ones that requires an advanced technique (mocks). This should cheer you up, as for once a good methodology doesn't add new rules and further worries, but removes one third of them, forbidding you to implement them!


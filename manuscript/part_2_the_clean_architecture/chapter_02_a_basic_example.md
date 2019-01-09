# Chapter 2 - A basic example

{icon: quote-right}
B> _Joshua/WOPR: Wouldn't you prefer a good game of chess?
B> _David: Later. Let's play Global Thermonuclear War.__
B> - Wargames (1983)

## Project overview

The goal of the "Rent-o-matic" project (fans of "Day of the Tentacle" may get the reference) is to create a simple search engine on top of a dataset of objects which are described by some quantities. The search engine shall allow to set some filters to narrow the search.
 
The objects in the dataset are houses for rent described by the following quantities:
 
* An unique identifier
* A size in square meters
* A renting price in Euro/day
* Latitude and longitude

The description of the house is purposely minimal, so that the whole project can easily fit in a chapter. The concepts that I will show are however easily extendable to more complex cases.

As pushed by the clean architecture model, we are interested in separating the different layers of the system.

I will follow the TDD methodology, but I will not show all the single steps to avoid this chapter becoming too long.

Remember that there are multiple ways to implement the clean architecture concepts, and the code you can come up with strongly depends on what your language of choice allows you to do. The following is an example of clean architecture in Python, and the implementation of the models, use cases and other components that I will show is just one of the possible solutions.

The full project is available on [GitHub](https://github.com/pycabook/rentomatic).

## Project setup

Follow the instructions I gave in the first chapter and create a virtual environment for the project, install Cookiecutter, and then create a project using the recommended template. For this first project use the name `rentomatic` as I did, so you can use the same code that I will show without having to change the name of the imported modules. You also want to use pytest, so answer yes to that question.

After you created the project install the requirements with

``` sh
$ pip install -r requirements/dev.txt
```

Try to run `py.test -svv` to check that everything is working correctly, and then remove the files `tests/test_rentomatic.py` and `rentomatic/rentomatic.py`.

In this chapter I will not explicitly state that I run the test suite, as I consider it part of the standard workflow. Every time we write a test you should run the suite and check that you get an error (or more), and the code that I give as a solution should make the test suite pass. You are free to try to implement your own code before copying my solution, obviously.

## Domain models

Let us start with a simple definition of the `Room` model. As said before, the clean architecture models are very lightweight, or at least they are lighter than their counterparts in common web frameworks.

Following the TDD methodology the first thing that I write are the tests. Create the `tests/domain/test_room.py` and put this code inside it

``` python
import uuid
from rentomatic.domain import room as r


def test_room_model_init():
    code = uuid.uuid4()
    room = r.Room(code, size=200, price=10,
                  longitude=-0.09998975,
                  latitude=51.75436293)
    assert room.code == code
    assert room.size == 200
    assert room.price == 10
    assert room.longitude == -0.09998975
    assert room.latitude == 51.75436293
```

Remember to create an `__init__.py` file in every subdirectory of `tests/`, so in this case create `tests/domain/__init__.py`. This test ensures that the model can be initialised with the correct values. All the parameters of the model are mandatory. Later we could want to make some of them optional, and in that case we will have to add the relevant tests.

Now let's write the `Room` class in the `rentomatic/domain/room.py` file.

``` python
class Room:
    def __init__(self, code, size, price, longitude, latitude):
        self.code = code
        self.size = size
        self.price = price
        self.latitude = latitude
        self.longitude = longitude
```

{icon: github}
B> Git tag: [chapter-2-domain-models-step-1](https://github.com/pycabook/rentomatic/tree/chapter-2-domain-models-step-1)

The model is very simple, and requires no further explanation. Given that we will receive data to initialise this model from other layers, and that this data is likely to be a dictionary, it is useful to create a method that initialises the model from this type of structure. The test for this method is 

``` python
def test_room_model_from_dict():
    code = uuid.uuid4()
    room = r.Room.from_dict(
        {
            'code': code,
            'size': 200,
            'price': 10,
            'longitude': -0.09998975,
            'latitude': 51.75436293
        }
    )
    assert room.code == code
    assert room.size == 200
    assert room.price == 10
    assert room.longitude == -0.09998975
    assert room.latitude == 51.75436293
```

while the implementation inside the `Room` class is

``` python
    @classmethod
    def from_dict(cls, adict):
        return cls(
            code=adict['code'],
            size=adict['size'],
            price=adict['price'],
            latitude=adict['latitude'],
            longitude=adict['longitude'],
        )
```

{icon: github}
B> Git tag: [chapter-2-domain-models-step-2](https://github.com/pycabook/rentomatic/tree/chapter-2-domain-models-step-2)

As you can see one of the benefits of a clean architecture is that each layer contains small pieces of code that, being isolated, shall perform simple tasks. In this case the model provides an initialisation API and stores the information inside the class.

It is often useful to compare models, and we will use this feature later in the project. The comparison operator can be added to any Python object through the `__eq__` method that receives another object and returns either `True` or `False`. Comparing `Room` fields might however result in a very big `and` chain of statements, so the first things I will do is to write a method to convert the object in a dictionary. The test goes in `tests/domain/test_room.py`

``` python
def test_room_model_to_dict():
    room_dict = {
        'code': uuid.uuid4(),
        'size': 200,
        'price': 10,
        'longitude': -0.09998975,
        'latitude': 51.75436293
    }

    room = r.Room.from_dict(room_dict)

    assert room.to_dict() == room_dict
```

and the implementation of the `to_dict` method is

``` python
    def to_dict(self):
        return {
            'code': self.code,
            'size': self.size,
            'price': self.price,
            'latitude': self.latitude,
            'longitude': self.longitude,
        }
```

{icon: github}
B> Git tag: [chapter-2-domain-models-step-3](https://github.com/pycabook/rentomatic/tree/chapter-2-domain-models-step-3)

Note that this is not yet a serialisation of the object, as the result is still a Python data structure and not a string.

At this point writing the comparison operator is very simple. The test goes in the same file as the previous test

``` python
def test_room_model_comparison():
    room_dict = {
        'code': uuid.uuid4(),
        'size': 200,
        'price': 10,
        'longitude': -0.09998975,
        'latitude': 51.75436293
    }
    room1 = r.Room.from_dict(room_dict)
    room2 = r.Room.from_dict(room_dict)

    assert room1 == room2
```

and the method of the `Room` class is

``` python
    def __eq__(self, other):
        return self.to_dict() == other.to_dict()
```

{icon: github}
B> Git tag: [chapter-2-domain-models-step-4](https://github.com/pycabook/rentomatic/tree/chapter-2-domain-models-step-4)

## Serializers

Outer layers can use the `Room` model, but if you want to return the model as a result of an API call you need a serializer.

The typical serialization format is JSON, as this is a broadly accepted standard for web-based APIs. The serializer is not part of the model, but is an external specialized class that receives the model instance and produces a representation of its structure and values.

To test the JSON serialization of our `Room` class put the following code into the file `tests/serializers/test_room_json_serializer.py`:

``` python
import json
import uuid

from rentomatic.serializers import room_json_serializer as ser
from rentomatic.domain import room as r


def test_serialize_domain_room():
    code = uuid.uuid4()

    room = r.Room(
        code=code,
        size=200,
        price=10,
        longitude=-0.09998975,
        latitude=51.75436293
    )

    expected_json = """
        {{
            "code": "{}",
            "size": 200,
            "price": 10,
            "longitude": -0.09998975,
            "latitude": 51.75436293
        }}
    """.format(code)

    json_room = json.dumps(room, cls=ser.RoomJsonEncoder)

    assert json.loads(json_room) == json.loads(expected_json)
```

Here, we create the `Room` object and write the expected JSON output (with some annoying escape sequences like `{{` and `}}` due to the clash with the `{}` syntax of Python strings `format` methos). Then we dump the `Room` object to a JSON string and compare the two. To compare the two we load them again into Python dictionaries, to avoid issues with the order of the attributes. Comparing Python dictionaries, indeed, doesn't consider the order of the dictionary fields, while comparing strings obviously does.

Put in the `rentomatic/serializers/room_json_serializer.py` file the code that makes the test pass

``` python
import json


class RoomJsonEncoder(json.JSONEncoder):

    def default(self, o):
        try:
            to_serialize = {
                'code': str(o.code),
                'size': o.size,
                'price': o.price,
                'latitude': o.latitude,
                'longitude': o.longitude,
            }
            return to_serialize
        except AttributeError:
            return super().default(o)
```

{icon: github}
B> Git tag: [chapter-2-serializers](https://github.com/pycabook/rentomatic/tree/chapter-2-serializers)

Providing a class that inherits from `json.JSONEncoder` let us use the `json.dumps(room, cls=RoomEncoder)` syntax to serialize the model. Note that we are not using the `to_dict` method, as the UUID code is not directly JSON serialisable. This means that there is a slight degree of code repetition in the two classes, which in my opinion is acceptable, being covered by tests. If you prefer, however, you can call the `to_dict` method and then adjust the code field with the `str` conversion.

## Use cases

It's time to implement the actual business logic that runs inside our application. Use cases are the places where this happens, and they might or might not be directly linked to the external API of the system. 

The simplest use case we can create is one that fetches all the rooms stored in the repository and returns them. In this first part we will not implement the filters to narrow the search. That part will be introduced in the next chapter when we will discuss error management.

The repository is our storage component, and according to the clean architecture it will be implemented in an outer level (external systems). We will access it as an interface, which in Python means that we will receive an object that we expect will expose a certain API. From the testing point of view the best way to run code that accesses an interface is to mock this latter. Put this code in the `tests/use_cases/test_room_list_use_case.py`

I will make use of pytest's powerful fixtures, but I will not introduce them. I highly recommend reading the [official documentation](https://docs.pytest.org/en/latest/fixture.html), which is very good and covers many different use cases.

``` python
import pytest
import uuid
from unittest import mock

from rentomatic.domain import room as r
from rentomatic.use_cases import room_list_use_case as uc


@pytest.fixture
def domain_rooms():
    room_1 = r.Room(
        code=uuid.uuid4(),
        size=215,
        price=39,
        longitude=-0.09998975,
        latitude=51.75436293,
    )

    room_2 = r.Room(
        code=uuid.uuid4(),
        size=405,
        price=66,
        longitude=0.18228006,
        latitude=51.74640997,
    )

    room_3 = r.Room(
        code=uuid.uuid4(),
        size=56,
        price=60,
        longitude=0.27891577,
        latitude=51.45994069,
    )

    room_4 = r.Room(
        code=uuid.uuid4(),
        size=93,
        price=48,
        longitude=0.33894476,
        latitude=51.39916678,
    )

    return [room_1, room_2, room_3, room_4]


def test_room_list_without_parameters(domain_rooms):
    repo = mock.Mock()
    repo.list.return_value = domain_rooms

    room_list_use_case = uc.RoomListUseCase(repo)
    result = room_list_use_case.execute()

    repo.list.assert_called_with()
    assert result == domain_rooms
```

The test is straightforward. First we mock the repository so that it provides a `list` method that returns the list of models we created above the test. Then we initialise the use case with the repository and execute it, collecting the result. The first thing we check is that the repository method was called without any parameter, and the second is the effective correctness of the result.

Calling the `list` method of the repository is an outgoing query action that the use case is supposed to perform, and according to the unit testing rules we should not test outgoing queries. We should however test how our system runs the outgoing query, that is the parameters used to run the query.

Put the implementation of the use case in the `rentomatic/use_cases/room_list_use_case.py`

``` python
class RoomListUseCase:

    def __init__(self, repo):
        self.repo = repo

    def execute(self):
        return self.repo.list()
```

This might seem too simple, but this particular use case is just a wrapper around a specific function of the repository. As a matter of fact, this use case doesn't contain any error check, which is something we didn't take into account yet. In the next chapter we will discuss requests and responses, and the use case will become slightly more complicated.

{icon: github}
B> Git tag: [chapter-2-use-cases](https://github.com/pycabook/rentomatic/tree/chapter-2-use-cases)

## The storage system

During the development of the use case we assumed it would receive an object that contains the data and exposes a `list` function. This object is generally speaking nicknamed "repository", being the source of information for the use case. It has nothing to do with the Git repository, though, so be careful not to mix the two nomenclatures.

The storage lives in the third layer of the clean architecture, the external systems. The elements in this layer are accessed by internal elements through an interface, which in Python just translates in exposing a given set of methods (in this case only `list`). It is worth noting that the level of abstraction provided by a repository in a clean architecture is higher than that provided by an ORM in a framework or by a tool like SQLAlchemy. The repository provides only the endpoints that the application needs, with an interface which is tailored on the specific business problems the application implements.

To clarify the matter in terms of concrete technologies, SQLAlchemy is a wonderful tool to abstract the access to an SQL database, so the internal implementation of the repository could use it to access a PostgreSQL database, for example. But the external API of the layer is not that provided by SQLAlchemy. The API is a reduced set of functions that the use cases call to get the data, and the internal implementation can use a wide range of solutions to achieve the same goal, from raw SQL queries to a complex system of remote calls through a RabbitMQ network.

A very important feature of the repository is that it can return domain models, and this is in line with what framework ORMs usually do. The elements in the third layer have access to all the elements defined in the internal layers, which means that domain models and use cases can be called and used directly from the repository.

For the sake of this simple example we will not deploy and use a real database system. Given what we said, we are free to implement the repository with the system that better suits our needs, and in this case I want to keep everything simple. We will thus create a very simple in-memory storage system loaded with some predefined data.

The first thing to do is to write some tests that document the public API of the repository. The file containing the tests is `tests/repository/test_memrepo.py`.

``` python
import pytest

from rentomatic.domain import room as r
from rentomatic.repository import memrepo


@pytest.fixture
def room_dicts():
    return [
        {
            'code': 'f853578c-fc0f-4e65-81b8-566c5dffa35a',
            'size': 215,
            'price': 39,
            'longitude': -0.09998975,
            'latitude': 51.75436293,
        },
        {
            'code': 'fe2c3195-aeff-487a-a08f-e0bdc0ec6e9a',
            'size': 405,
            'price': 66,
            'longitude': 0.18228006,
            'latitude': 51.74640997,
        },
        {
            'code': '913694c6-435a-4366-ba0d-da5334a611b2',
            'size': 56,
            'price': 60,
            'longitude': 0.27891577,
            'latitude': 51.45994069,
        },
        {
            'code': 'eed76e77-55c1-41ce-985d-ca49bf6c0585',
            'size': 93,
            'price': 48,
            'longitude': 0.33894476,
            'latitude': 51.39916678,
        }
    ]


def test_repository_list_without_parameters(room_dicts):
    repo = memrepo.MemRepo(room_dicts)

    rooms = [r.Room.from_dict(i) for i in room_dicts]

    assert repo.list() == rooms
```

In this case we need a single test that checks the behaviour of the `list` method. The implementation that passes the test goes in the file `rentomatic/repository/memrepo.py`

``` python
from rentomatic.domain import room as r


class MemRepo:
    def __init__(self, data):
        self.data = data

    def list(self):
        return [r.Room.from_dict(i) for i in self.data]
```

{icon: github}
B> Git tag: [chapter-2-storage-system](https://github.com/pycabook/rentomatic/tree/chapter-2-storage-system)

You can easily imagine this class being the wrapper around a real database or any other storage type. While the code might become more complex, the structure of the repository is the same, with a single public method `list`. I will dig into database repositories in a later chapter.

## A command line interface

So far we created the domain models, the serializers, the use cases and the repository, but we are still missing a system that glues everything together. This system has to get the call parameters from the user, initialise a use case with a repository, run the use case that fetches the domain models from the repository, and return them to the user.

Let's see now how the architecture that we just created can interact with an external system like a CLI. The power of a clean architecture is that the external systems are pluggable, which means that we can defer the decision about the detail of the system we want to use. In this case we want to give the user an interface to query the system and to get a list of the rooms contained in the storage system, and the simplest choice is a command line tool.

Later we will create a REST endpoint and we will expose it though a Web server, and it will be clear why the architecture that we created is so powerful.

For the time being, create a file `cli.py` in the same directory that contains `setup.py`. This is a simple Python script that doesn't need any specific option to run, as it just queries the storage for all the domain models contained there. The content of the file is the following

``` python
#!/usr/bin/env python

from rentomatic.repository import memrepo as mr
from rentomatic.use_cases import room_list_use_case as uc

repo = mr.MemRepo([])
use_case = uc.RoomListUseCase(repo)
result = use_case.execute()

print(result)
```

{icon: github}
B> Git tag: [chapter-2-command-line-interface-step-1](https://github.com/pycabook/rentomatic/tree/chapter-2-command-line-interface-step-1)

You can execute this file with `python cli.py` or, if you prefer, run `chmod +x cli.py` (which make it executable) and then run it with `./cli.py` directly. The expected result is an empty list

``` sh
$ ./cli.py
[]
```

which is correct as the `MemRepo` class in the `cli.py` file has been initialised with an empty list. The simple in-memory storage that we use has no persistence, so every time we create it we have to load some data in it. This has been done to keep the storage layer simple, but keep in mind that if the storage was a proper database this part of the code would connect to it but there would be no need to load data in it.

The important part of the script are the three lines

``` python
repo = mr.MemRepo([])
use_case = uc.RoomListUseCase(repo)
result = use_case.execute()
```

which initialise the repository, use it to initialise the use case, and run this latter. This is in general how you end up using your clean architecture in whatever external system you will plug into it. You initialise other systems, you initialise the use case, and you collect the results.

For the sake of demonstration, let's define some data in the file and load them in the repository

``` python
#!/usr/bin/env python

from rentomatic.repository import memrepo as mr
from rentomatic.use_cases import room_list_use_case as uc

room1 = {
    'code': 'f853578c-fc0f-4e65-81b8-566c5dffa35a',
    'size': 215,
    'price': 39,
    'longitude': -0.09998975,
    'latitude': 51.75436293,
}

room2 = {
    'code': 'fe2c3195-aeff-487a-a08f-e0bdc0ec6e9a',
    'size': 405,
    'price': 66,
    'longitude': 0.18228006,
    'latitude': 51.74640997,
}

room3 = {
    'code': '913694c6-435a-4366-ba0d-da5334a611b2',
    'size': 56,
    'price': 60,
    'longitude': 0.27891577,
    'latitude': 51.45994069,
}

repo = mr.MemRepo([room1, room2, room3])
use_case = uc.RoomListUseCase(repo)

result = use_case.execute()

print([room.to_dict() for room in result])
```

{icon: github}
B> Git tag: [chapter-2-command-line-interface-step-2](https://github.com/pycabook/rentomatic/tree/chapter-2-command-line-interface-step-2)

Again, remember that this is due to the trivial nature of our storage, and not to the architecture of the system. Note that I changed the `print` instruction as the repository returns domain models and it printing them would result in a list of strings like `<rentomatic.domain.room.Room object at 0x7fb815ec04e0>`, which is not really helpful.

If you run the command line tool now, you will get a richer result than before

``` sh
$ ./cli.py
[{'code': 'f853578c-fc0f-4e65-81b8-566c5dffa35a', 'size': 215, 'price': 39, 'latitude': 51.75436293,
    'longitude': -0.09998975}, {'code': 'fe2c3195-aeff-487a-a08f-e0bdc0ec6e9a', 'size': 405, 'price': 66,
    'latitude': 51.74640997, 'longitude': 0.18228006}, {'code': '913694c6-435a-4366-ba0d-da5334a611b2',
    'size': 56, 'price': 60, 'latitude': 51.45994069, 'longitude': 0.27891577}]
```

## HTTP API

In this section I will go through the creation of an HTTP endpoint for the room list use case. An HTTP endpoint is a URL exposed by a Web server that runs a specific logic and returns values, often formatted as JSON, which is a widely used format for this type of API.

The semantic of URLs, that is their structure and the requests they can accept, comes from the REST recommendations. REST is however not part of the clean architecture, which means that you can choose to model your URLs according to whatever scheme you might prefer.

To expose the HTTP endpoint we need a web server written in Python, and in this case I chose Flask. Flask is a lightweight web server with a modular structure that provides just the parts that the user needs. In particular, we will not use any database/ORM, since we already implemented our own repository layer. The clean architecture works perfectly with other frameworks, like Django, web2py, Pylons, and so on.

Let us start updating the requirements files. The `requirements/prod.txt` file shall contain Flask, as this package contains a script that runs a local webserver that we can use to expose the endpoint

``` text
Flask
```

The `requirements/test.txt` file will contain the pytest extension to work with Flask (more on this later)

``` text
-r prod.txt
pytest
tox
coverage
pytest-cov
pytest-flask
```

{icon: github}
B> Git tag: [chapter-2-http-api-step-1](https://github.com/pycabook/rentomatic/tree/chapter-2-http-api-step-1)

Remember to run `pip install -r requirements/dev.txt` again after those changes to install the new packages in your virtual environment.

The setup of a Flask application is not complex, but a lot of concepts are involved, and since this is not a tutorial on Flask I will run quickly through these steps. I will however provide links to the Flask documentation for every concept.

I usually define different configurations for my testing, development, and production environments. Since the Flask application can be configured using a plain Python object ([documentation](http://flask.pocoo.org/docs/latest/api/#flask.Config.from_object)), I created the file `rentomatic/flask_settings.py` to host those objects

``` python
class Config(object):
    """Base configuration."""


class ProdConfig(Config):
    """Production configuration."""
    ENV = 'production'
    DEBUG = False


class DevConfig(Config):
    """Development configuration."""
    ENV = 'development'
    DEBUG = True


class TestConfig(Config):
    """Test configuration."""
    ENV = 'test'
    TESTING = True
    DEBUG = True
```

Read [this page](http://flask.pocoo.org/docs/latest/config/) to know more about Flask configuration parameters.

Now we need a function that initialises the Flask application ([documentation](http://flask.pocoo.org/docs/latest/patterns/appfactories/)), configures it, and registers the blueprints ([documentation](http://flask.pocoo.org/docs/latest/blueprints/)). The file `rentomatic/app.py` contains the following code, which is an app factory

``` python
from flask import Flask

from rentomatic.rest import room
from rentomatic.flask_settings import DevConfig


def create_app(config_object=DevConfig):
    app = Flask(__name__)
    app.config.from_object(config_object)
    app.register_blueprint(room.blueprint)
    return app
```

Before we create the proper setup of the webserver we want to create the endpoint that will be exposed. Endpoints are ultimately functions that are run when a use sends a request to a certain URL, so we can still work with TDD, as the final goal is to have code that produces certain results.

The problem we have testing an endpoint is that we need the webserver to be up and running when we hit the test URLs. This time the webserver is not an external system, that we can mock to test the correct use of its API, but is part of our system, so we need to run it. This is what the `pytest-flask` extension provides, in the form of pytest fixtures, in particular the `client` fixture.

This fixture hides a lot of automation, so it might be considered a bit "magic" at a first glance. When you install the `pytest-flask` extension the fixture is available automatically, so you don't need to import it. Moreover, it tries to access another fixture named `app` that you have to define. This is thus the first thing to do.

Fixtures can be defined directly in your tests file, but if we want a fixture to be globally available the best place to define it is the file `conftest.py` which is automatically loaded by pytest. As you can see there is a great deal of automation, and if you are not aware of it you might be surprised by the results, or frustrated by the errors.

Lets create the file `tests/conftest.py`

``` python
import pytest


from rentomatic.app import create_app
from rentomatic.flask_settings import TestConfig


@pytest.yield_fixture(scope='function')
def app():
    return create_app(TestConfig)
```

First of all the fixture has been defined with the scope of a function, which means that it will be recreated for each test. This is good, as tests should be isolated, and we do not want to resuse the application that another test has already tainted.

The function itself runs the app factory to create a Flask app, using the `TestConfig` configuration from `flask_settings`, which sets the `TESTING` flag to `True`. You can find the description of these flags in the [official documentation](http://flask.pocoo.org/docs/1.0/config/).

At this point we can write the test for our endpoint. Create the file `tests/rest/test_get_rooms_list.py`

``` python
import json
from unittest import mock

from rentomatic.domain.room import Room

room_dict = {
    'code': '3251a5bd-86be-428d-8ae9-6e51a8048c33',
    'size': 200,
    'price': 10,
    'longitude': -0.09998975,
    'latitude': 51.75436293
}

room = Room.from_dict(room_dict)

rooms = [room]


@mock.patch('rentomatic.use_cases.room_list_use_case.RoomListUseCase')
def test_get(mock_use_case, client):
    mock_use_case().execute.return_value = rooms

    http_response = client.get('/rooms')

    assert json.loads(http_response.data.decode('UTF-8')) == [room_dict]
    mock_use_case().execute.assert_called_with()
    assert http_response.status_code == 200
    assert http_response.mimetype == 'application/json'
```

Let's comment it section by section.

``` python
import json
from unittest import mock

from rentomatic.domain.room import Room

room_dict = {
    'code': '3251a5bd-86be-428d-8ae9-6e51a8048c33',
    'size': 200,
    'price': 10,
    'longitude': -0.09998975,
    'latitude': 51.75436293
}

room = Room.from_dict(room_dict)

rooms = [room]
```

The first part contains imports and sets up a room from a dictionary. This way we can later directly compare the content of the initial dictionary with the result of the API endpoint. Remember that the API returns JSON content, and we can easily convert JSON data into simple Python structures, so starting from a dictionary can come in handy.

``` python
@mock.patch('rentomatic.use_cases.room_list_use_case.RoomListUseCase')
def test_get(mock_use_case, client):
```

This is the only test that we have for the time being. During the whole test we mock the use case, as we are not interested in running it. We are however interested in checking the arguments it is called with, and a mock can provide this information. The test receives the mock from the the `patch` decorator and `client`, which is one of the fixtures provided by `pytest-flask`. The `client` fixture automatically loads the `app` one, which we defined in `conftest.py`, and is an object that simulates an HTTP client that can access the API endpoints and store the responses of the server.

``` python
    mock_use_case().execute.return_value = rooms

    http_response = client.get('/rooms')

    assert json.loads(http_response.data.decode('UTF-8')) == [room_dict]
    mock_use_case().execute.assert_called_with()
    assert http_response.status_code == 200
    assert http_response.mimetype == 'application/json'
```

The first line initialises the `execute` method of the mock. Pay attention that `execute` is run on an instence of the `RoomListUseCase` class, and not on the class itself, which is why we call the mock (`mock_use_case()`) before accessing the method.

The central part of the test is the line where we `get` the API endpoint, which sends an HTTP GET requests and collects the server's response.

After this we check that the data contained in the response is actually a JSON that represents the `room_dict` structure, that the `execute` method has been called without any parameters, that the HTTP response status code is 200, and last that the server sends the correct mimetype back.

It's time to write the endpoint, where we will finally see all the pieces of the architecture working together. Let me show you a template for the minimal Flask endpoint we can create

``` python
blueprint = Blueprint('room', __name__)


@blueprint.route('/rooms', methods=['GET'])
def room():
    [LOGIC]
    return Response([JSON DATA],
                    mimetype='application/json',
                    status=[STATUS])
```

As you can see the structure is really simple. Apart from setting the blueprint, which is the way Flask registers endpoints, we create a simple function that runs the endpoint, and we decorate it assigning the `/rooms` endpoint that serves `GET` requests. The function will run some logic and eventually return a `Response` that contains JSON data, the correct mimetype, and an HTTP status that represents the success or failure of the logic.

The above template becomes the following code that you can put in `rentomatic/rest/room.py` [^restroom]

[^restroom]: The Rent-o-matic rest/room is obviously connected with Day of the Tentacle's Chron-O-John

``` python
import json

from flask import Blueprint, Response

from rentomatic.repository import memrepo as mr
from rentomatic.use_cases import room_list_use_case as uc
from rentomatic.serializers import room_json_serializer as ser

blueprint = Blueprint('room', __name__)

room1 = {
    'code': 'f853578c-fc0f-4e65-81b8-566c5dffa35a',
    'size': 215,
    'price': 39,
    'longitude': -0.09998975,
    'latitude': 51.75436293,
}

room2 = {
    'code': 'fe2c3195-aeff-487a-a08f-e0bdc0ec6e9a',
    'size': 405,
    'price': 66,
    'longitude': 0.18228006,
    'latitude': 51.74640997,
}

room3 = {
    'code': '913694c6-435a-4366-ba0d-da5334a611b2',
    'size': 56,
    'price': 60,
    'longitude': 0.27891577,
    'latitude': 51.45994069,
}


@blueprint.route('/rooms', methods=['GET'])
def room():
    repo = mr.MemRepo([room1, room2, room3])
    use_case = uc.RoomListUseCase(repo)
    result = use_case.execute()

    return Response(json.dumps(result, cls=ser.RoomJsonEncoder),
                    mimetype='application/json',
                    status=200)
```

{icon: github}
B> Git tag: [chapter-2-http-api-step-2](https://github.com/pycabook/rentomatic/tree/chapter-2-http-api-step-2)

As I did before, I initialised the memory storage with some data to give the use case something to return. Please note that the code that runs the use case is

``` python
    repo = mr.MemRepo([room1, room2, room3])
    use_case = uc.RoomListUseCase(repo)
    result = use_case.execute()
```

which is exactly the same code that we run in the command line interface. The rest of the code creates a proper HTTP response, serializing the result of the use case using the specific serializer that matches the domain model, and setting the HTTP status to 200 (success)

``` python
    return Response(json.dumps(result, cls=ser.RoomJsonEncoder),
                    mimetype='application/json',
                    status=200)
```

This shows you the power of the clean architecture in a nutshell. Writing a CLI interface or a Web service is different only in the presentation layer, not in the logic, which is contained in the use case.

Now that we defined the endpoint we can finalise the configuration of the webserver, so that we can access the endpoint with a browser. This is not strictly part of the clean architecture, but as already happened for the CLI interface I want you to see the final result, to get the whole picture and also to enjoy the effort you put in following the whole discussion up to this point.

Python web applications expose a common interface called [Web Server Gateway Interface](https://en.wikipedia.org/wiki/Web_Server_Gateway_Interface) or WSGI. So to run the Flask development web server we have to define a `wsgi.py` file in the main folder of the project, i.e. in the same directory of the `cli.py` file

``` python
from rentomatic.app import create_app


app = create_app()
```

{icon: github}
B> Git tag: [chapter-2-http-api-step-3](https://github.com/pycabook/rentomatic/tree/chapter-2-http-api-step-3)

When the Flask Command Line Interface (http://flask.pocoo.org/docs/1.0/cli/) runs it looks for a file named `wsgi.py` and lods it, expecting it to contain an `app` variable that is an instance of the `Flask` object. As the `create_app` is a factory we just need to execute it.

At this point you can execute `flask run` in the directory that contains this file and you should see a nice message like

``` txt
 * Running on http://127.0.0.1:5000/ (Press CTRL+C to quit)
```

At this point you can point your browser to

```
http://localhost:5000/rooms
```

and enjoy the JSON returned by the first endpoint of your web application.

## Conclusions

I hope you can now appreciate the power of the layered architecture that we created. We definitely wrote a lot of code to "just" print out a list of models, but the code we wrote is a skeleton that can easily be extended and modified. It is also fully tested, which is a part of the implementation that many software projects struggle with.

The use case I presented is purposely very simple. It doesn't require any input and it cannot return error conditions, so the code we wrote completely ignored input validation and error management. These topics are however extremely important, so we need to discuss how a clean architecture can deal with them.

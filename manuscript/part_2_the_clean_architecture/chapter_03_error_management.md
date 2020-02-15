# Chapter 3 - Error management

{icon: quote-right}
B> _You sent them out there and you didn't even warn them! Why didn't you warn them, Burke?_
B> - Aliens (1986)

## Introduction

In every software project, a great part of the code is dedicated to error management, and this code has to be rock solid. Error management is a complex topic, and there is always a corner case that we left out, or a condition that we supposed could never fail, while it does.

In a clean architecture, the main process is the creation of use cases and their execution. This is, therefore, the main source of errors, and the use cases layer is where we have to implement the error management. Errors can obviously come from the domain models layer, but since those models are created by the use cases the errors that are not managed by the models themselves automatically become errors of the use cases.

To start working on possible errors and understand how to manage them, I will expand the `RoomListUseCase` to support filters that can be used to select a subset of the `Room` objects in storage.

The `filters` argument could be, for example, a dictionary that contains attributes of the `Room` model and the thresholds to apply to them. Once we accept such a rich structure, we open our use case to all sorts of errors: attributes that do not exist in the `Room` model, thresholds of the wrong type, filters that make the storage layer crash, and so on. All these considerations have to be taken into account by the use case.

In particular, we can divide the error management code into two different areas. The first one represents and manages requests, that is, the input data that reaches our use case. The second one covers the way we return results from the use case through responses, the output data. These two concepts shouldn't be confused with HTTP requests and responses, even though there are similarities. We are considering here the way data can be passed to and received from use cases, and how to manage errors. This has nothing to do with the possible use of this architecture to expose an HTTP API.

Request and response objects are an important part of a clean architecture, as they transport call parameters, inputs and results from outside the application into the use cases layer.

More specifically, requests are objects created from incoming API calls, thus they shall deal with things like incorrect values, missing parameters, wrong formats, and so on. Responses, on the other hand, have to contain the actual results of the API calls, but shall also be able to represent error cases and deliver rich information on what happened.

The actual implementation of request and response objects is completely free, the clean architecture says nothing about them. The decision on how to pack and represent data is up to us.

## Basic requests and responses

We can implement structured requests before we expand the use case to accept filters. We just need a `RoomListRequestObject` that can be initialised without parameters, so let us create the file `tests/request_objects/test_room_list_request_objects.py` and put there a test for this object.

``` python
from rentomatic.request_objects import room_list_request_object as req


def test_build_room_list_request_object_without_parameters():
    request = req.RoomListRequestObject()

    assert bool(request) is True


def test_build_room_list_request_object_from_empty_dict():
    request = req.RoomListRequestObject.from_dict({})

    assert bool(request) is True
```

While at the moment this request object is basically empty, it will come in handy as soon as we start having parameters for the list use case. The code of the `RoomListRequestObject` is the following and goes into the `rentomatic/request_objects/room_list_request_object.py` file

``` python
class RoomListRequestObject:
    @classmethod
    def from_dict(cls, adict):
        return cls()

    def __bool__(self):
        return True
```

{icon: github}
B> Git tag: [chapter-3-basic-requests-and-responses-step-1](https://github.com/pycabook/rentomatic/tree/chapter-3-basic-requests-and-responses-step-1)

The response object is also very simple since for the moment we just need to return a successful result. Unlike the request, the response is not linked to any particular use case, so the test file can be named `tests/response_objects/test_response_objects.py`

``` python
from rentomatic.response_objects import response_objects as res


def test_response_success_is_true():
    assert bool(res.ResponseSuccess()) is True
```

and the actual response object is in the file `rentomatic/response_objects/response_objects.py`

``` python
class ResponseSuccess:

    def __init__(self, value=None):
        self.value = value

    def __bool__(self):
        return True
```

{icon: github}
B> Git tag: [chapter-3-basic-requests-and-responses-step-2](https://github.com/pycabook/rentomatic/tree/chapter-3-basic-requests-and-responses-step-2)

With these two objects, we just laid the foundations for richer management of input and outputs of the use case, especially in the case of error conditions.

## Requests and responses in a use case

Let's implement the request and response objects that we developed into the use case. The new version of `tests/use_cases/test_room_list_use_case.py` is the following

``` python
import pytest
import uuid
from unittest import mock

from rentomatic.domain import room as r
from rentomatic.use_cases import room_list_use_case as uc
from rentomatic.request_objects import room_list_request_object as req


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
    request = req.RoomListRequestObject()

    response = room_list_use_case.execute(request)

    assert bool(response) is True
    repo.list.assert_called_with()
    assert response.value == domain_rooms
```

The new version of the `rentomatic/use_cases/room_list_use_case.py` file is the following

``` python
from rentomatic.response_objects import response_objects as res


class RoomListUseCase:

    def __init__(self, repo):
        self.repo = repo

    def execute(self, request):
        rooms = self.repo.list()
        return res.ResponseSuccess(rooms)
```

{icon: github}
B> Git tag: [chapter-3-requests-and-responses-in-a-use-case](https://github.com/pycabook/rentomatic/tree/chapter-3-requests-and-responses-in-a-use-case)

Now we have a standard way to pack input and output values, and the above pattern is valid for every use case we can create. We are still missing some features, however, because so far requests and responses are not used to perform error management.

## Request validation

The `filters` parameter that we want to add to the use case allows the caller to add conditions to narrow the results of the model list operation, using a notation `<attribute>__<operator>`. For example, specifying `filters={'price__lt': 100}` should return all the results with a price lower than 100. 

Since the `Room` model has many attributes the number of possible filters is very high, simplicity's sake, I will consider the following cases:

* The `code` attribute supports only `__eq`, which finds the room with the specific code if it exists
* The `price` attribute supports `__eq`, `__lt`, and `__gt`
* All other attributes cannot be used in filters

The first thing to do is to change the request object, starting from the test. The new version of the `tests/request_objects/test_room_list_request_object.py` file is the following

``` python
import pytest

from rentomatic.request_objects import room_list_request_object as req


def test_build_room_list_request_object_without_parameters():
    request = req.RoomListRequestObject()

    assert request.filters is None
    assert bool(request) is True


def test_build_room_list_request_object_from_empty_dict():
    request = req.RoomListRequestObject.from_dict({})

    assert request.filters is None
    assert bool(request) is True


def test_build_room_list_request_object_with_empty_filters():
    request = req.RoomListRequestObject(filters={})

    assert request.filters == {}
    assert bool(request) is True


def test_build_room_list_request_object_from_dict_with_empty_filters():
    request = req.RoomListRequestObject.from_dict({'filters': {}})

    assert request.filters == {}
    assert bool(request) is True


def test_build_room_list_request_object_from_dict_with_filters_wrong():
    request = req.RoomListRequestObject.from_dict({'filters': {'a': 1}})

    assert request.has_errors()
    assert request.errors[0]['parameter'] == 'filters'
    assert bool(request) is False


def test_build_room_list_request_object_from_dict_with_invalid_filters():
    request = req.RoomListRequestObject.from_dict({'filters': 5})

    assert request.has_errors()
    assert request.errors[0]['parameter'] == 'filters'
    assert bool(request) is False


@pytest.mark.parametrize(
    'key',
    ['code__eq', 'price__eq', 'price__lt', 'price__gt']
)
def test_build_room_list_request_object_accepted_filters(key):
    filters = {key: 1}

    request = req.RoomListRequestObject.from_dict({'filters': filters})

    assert request.filters == filters
    assert bool(request) is True


@pytest.mark.parametrize(
    'key',
    ['code__lt', 'code__gt']
)
def test_build_room_list_request_object_rejected_filters(key):
    filters = {key: 1}

    request = req.RoomListRequestObject.from_dict({'filters': filters})

    assert request.has_errors()
    assert request.errors[0]['parameter'] == 'filters'
    assert bool(request) is False
```

As you can see I added the `assert request.filters is None` check to the original two tests, then I added 6 tests for the filters syntax. Remember that if you are following TDD you should add these tests one at a time and change the code accordingly; here I am only showing you the final result of the process.

In particular, note that I used the `pytest.mark.parametrize` decorator to run the same test on multiple values, the accepted filters in `test_build_room_list_request_object_accepted_filters` and the filters that we don't consider valid in `test_build_room_list_request_object_rejected_filters`.

The core idea here is that requests are customised for use cases, so they can contain the logic that validates the arguments used to instantiate them. The request is valid or invalid before it reaches the use case, so it is not the responsibility of the latter to check that the input values have proper values or a proper format.

To make the tests pass we have to change our `RoomListRequestObject` class. There are obviously multiple possible solutions that you can come up with, and I recommend you to try to find your own. This is the one I usually employ. The file `rentomatic/request_objects/room_list_request_object.py` becomes

``` python
import collections


class InvalidRequestObject:

    def __init__(self):
        self.errors = []

    def add_error(self, parameter, message):
        self.errors.append({'parameter': parameter, 'message': message})

    def has_errors(self):
        return len(self.errors) > 0

    def __bool__(self):
        return False


class ValidRequestObject:

    @classmethod
    def from_dict(cls, adict):
        raise NotImplementedError

    def __bool__(self):
        return True


class RoomListRequestObject(ValidRequestObject):

    accepted_filters = ['code__eq', 'price__eq', 'price__lt', 'price__gt']

    def __init__(self, filters=None):
        self.filters = filters

    @classmethod
    def from_dict(cls, adict):
        invalid_req = InvalidRequestObject()

        if 'filters' in adict:
            if not isinstance(adict['filters'], collections.Mapping):
                invalid_req.add_error('filters', 'Is not iterable')
                return invalid_req

            for key, value in adict['filters'].items():
                if key not in cls.accepted_filters:
                    invalid_req.add_error(
                        'filters',
                        'Key {} cannot be used'.format(key)
                    )

        if invalid_req.has_errors():
            return invalid_req

        return cls(filters=adict.get('filters', None))
```

{icon: github}
B> Git tag: [chapter-3-request-validation](https://github.com/pycabook/rentomatic/tree/chapter-3-request-validation)

Let me review this new code bit by bit.

First of all, two helper classes have been introduced, `ValidRequestObject` and `InvalidRequestObject`. They are different because an invalid request shall contain the validation errors, but both can be used as booleans. 

Second, the `RoomListRequestObject` accepts an optional `filters` parameter when instantiated. There are no validation checks in the `__init__` method because this is considered to be an internal method that gets called when the parameters have already been validated.

Last, the `from_dict()` method performs the validation of the `filters` parameter, if it is present. I made use of the `collections.Mapping` abstract base class to check if the incoming parameter is a dictionary-like object and return either an `InvalidRequestObject` or a `RoomListRequestObject` instance (which is a subclass of `ValidRequestObject`).

## Responses and failures

There is a wide range of errors that can happen while the use case code is executed. Validation errors, as we just discussed in the previous section, but also business logic errors or errors that come from the repository layer or other external systems that the use case interfaces with. Whatever the error, the use case shall always return an object with a known structure (the response), so we need a new object that provides good support for different types of failures.

As happened for the requests there is no unique way to provide such an object, and the following code is just one of the possible solutions.

The new version of the `tests/response_objects/test_response_objects.py` file is the following

``` python
import pytest

from rentomatic.response_objects import response_objects as res
from rentomatic.request_objects import room_list_request_object as req


@pytest.fixture
def response_value():
    return {'key': ['value1', 'value2']}


@pytest.fixture
def response_type():
    return 'ResponseError'


@pytest.fixture
def response_message():
    return 'This is a response error'


def test_response_success_is_true(response_value):
    assert bool(res.ResponseSuccess(response_value)) is True


def test_response_success_has_type_and_value(response_value):
    response = res.ResponseSuccess(response_value)

    assert response.type == res.ResponseSuccess.SUCCESS
    assert response.value == response_value


def test_response_failure_is_false(response_type, response_message):
    assert bool(res.ResponseFailure(response_type, response_message)) is False


def test_response_failure_has_type_and_message(
        response_type, response_message):
    response = res.ResponseFailure(response_type, response_message)

    assert response.type == response_type
    assert response.message == response_message


def test_response_failure_contains_value(response_type, response_message):
    response = res.ResponseFailure(response_type, response_message)

    assert response.value == {
        'type': response_type, 'message': response_message}


def test_response_failure_initialisation_with_exception(response_type):
    response = res.ResponseFailure(
        response_type, Exception('Just an error message'))

    assert bool(response) is False
    assert response.type == response_type
    assert response.message == "Exception: Just an error message"


def test_response_failure_from_empty_invalid_request_object():
    response = res.ResponseFailure.build_from_invalid_request_object(
        req.InvalidRequestObject())

    assert bool(response) is False
    assert response.type == res.ResponseFailure.PARAMETERS_ERROR


def test_response_failure_from_invalid_request_object_with_errors():
    request_object = req.InvalidRequestObject()
    request_object.add_error('path', 'Is mandatory')
    request_object.add_error('path', "can't be blank")

    response = res.ResponseFailure.build_from_invalid_request_object(
        request_object)

    assert bool(response) is False
    assert response.type == res.ResponseFailure.PARAMETERS_ERROR
    assert response.message == "path: Is mandatory\npath: can't be blank"


def test_response_failure_build_resource_error():
    response = res.ResponseFailure.build_resource_error("test message")

    assert bool(response) is False
    assert response.type == res.ResponseFailure.RESOURCE_ERROR
    assert response.message == "test message"


def test_response_failure_build_parameters_error():
    response = res.ResponseFailure.build_parameters_error("test message")

    assert bool(response) is False
    assert response.type == res.ResponseFailure.PARAMETERS_ERROR
    assert response.message == "test message"


def test_response_failure_build_system_error():
    response = res.ResponseFailure.build_system_error("test message")

    assert bool(response) is False
    assert response.type == res.ResponseFailure.SYSTEM_ERROR
    assert response.message == "test message"
```

Let's have a closer look at the tests contained in this file before moving to the code that implements a solution. The first part contains just the imports and some pytest fixtures to make it easier to write the tests

``` python
import pytest

from rentomatic.response_objects import response_objects as res
from rentomatic.request_objects import room_list_request_object as req


@pytest.fixture
def response_value():
    return {'key': ['value1', 'value2']}


@pytest.fixture
def response_type():
    return 'ResponseError'


@pytest.fixture
def response_message():
    return 'This is a response error'
```

The first two tests check that `ResponseSuccess` can be used as a boolean (this test was already present), that it provides a type, and that it can store a value.

``` python
def test_response_success_is_true(response_value):
    assert bool(res.ResponseSuccess(response_value)) is True


def test_response_success_has_type_and_value(response_value):
    response = res.ResponseSuccess(response_value)

    assert response.type == res.ResponseSuccess.SUCCESS
    assert response.value == response_value
```

The remaining tests are all about `ResponseFailure`. A test to check that it behaves like a boolean

``` python
def test_response_failure_is_false(response_type, response_message):
    assert bool(res.ResponseFailure(response_type, response_message)) is False
```

A test to check that it can be initialised with a type and a message, and that those values are stored inside the object. A second test to verify the class exposes a `value` attribute that contains both the type and the message.

``` python
def test_response_failure_has_type_and_message(
        response_type, response_message):
    response = res.ResponseFailure(response_type, response_message)

    assert response.type == response_type
    assert response.message == response_message


def test_response_failure_contains_value(response_type, response_message):
    response = res.ResponseFailure(response_type, response_message)

    assert response.value == {
        'type': response_type, 'message': response_message}
```

We sometimes want to create responses from Python exceptions that can happen in a use case, so we test that `ResponseFailure` objects can be initialised with a generic exception. We also check that the message is formatted properly

``` python
def test_response_failure_initialisation_with_exception(response_type):
    response = res.ResponseFailure(
        response_type, Exception('Just an error message'))

    assert bool(response) is False
    assert response.type == response_type
    assert response.message == "Exception: Just an error message"
```

We want to be able to build a response directly from an invalid request, getting all the errors contained in the latter.

``` python
def test_response_failure_from_empty_invalid_request_object():
    response = res.ResponseFailure.build_from_invalid_request_object(
        req.InvalidRequestObject())

    assert bool(response) is False
    assert response.type == res.ResponseFailure.PARAMETERS_ERROR


def test_response_failure_from_invalid_request_object_with_errors():
    request_object = req.InvalidRequestObject()
    request_object.add_error('path', 'Is mandatory')
    request_object.add_error('path', "can't be blank")

    response = res.ResponseFailure.build_from_invalid_request_object(
        request_object)

    assert bool(response) is False
    assert response.type == res.ResponseFailure.PARAMETERS_ERROR
    assert response.message == "path: Is mandatory\npath: can't be blank"
```

The last three tests check that the `ResponseFailure` can create three specific errors, represented by the `RESOURCE_ERROR`, `PARAMETERS_ERROR`, and `SYSTEM_ERROR` class attributes. This categorization is an attempt to capture the different types of issues that can happen when dealing with an external system through an API. `RESOURCE_ERROR` contains all those errors that are related to the resources contained in the repository, for instance when you cannot find an entry given its unique ID. `PARAMETERS_ERROR` describes all those errors that occur when the request parameters are wrong or missing. `SYSTEM_ERROR` encompass the errors that happen in the underlying system at an operating system level, such as a failure in a filesystem operation, or a network connection error while fetching data from the database.

``` python
def test_response_failure_build_resource_error():
    response = res.ResponseFailure.build_resource_error("test message")

    assert bool(response) is False
    assert response.type == res.ResponseFailure.RESOURCE_ERROR
    assert response.message == "test message"


def test_response_failure_build_parameters_error():
    response = res.ResponseFailure.build_parameters_error("test message")

    assert bool(response) is False
    assert response.type == res.ResponseFailure.PARAMETERS_ERROR
    assert response.message == "test message"


def test_response_failure_build_system_error():
    response = res.ResponseFailure.build_system_error("test message")

    assert bool(response) is False
    assert response.type == res.ResponseFailure.SYSTEM_ERROR
    assert response.message == "test message"
```

Let's write the classes that make the tests pass in `rentomatic/response_objects/response_objects.py`

``` python
class ResponseFailure:
    RESOURCE_ERROR = 'ResourceError'
    PARAMETERS_ERROR = 'ParametersError'
    SYSTEM_ERROR = 'SystemError'

    def __init__(self, type_, message):
        self.type = type_
        self.message = self._format_message(message)

    def _format_message(self, msg):
        if isinstance(msg, Exception):
            return "{}: {}".format(msg.__class__.__name__, "{}".format(msg))
        return msg

    @property
    def value(self):
        return {'type': self.type, 'message': self.message}

    def __bool__(self):
        return False

    @classmethod
    def build_from_invalid_request_object(cls, invalid_request_object):
        message = "\n".join(["{}: {}".format(err['parameter'], err['message'])
                             for err in invalid_request_object.errors])
        return cls(cls.PARAMETERS_ERROR, message)

    @classmethod
    def build_resource_error(cls, message=None):
        return cls(cls.RESOURCE_ERROR, message)

    @classmethod
    def build_system_error(cls, message=None):
        return cls(cls.SYSTEM_ERROR, message)

    @classmethod
    def build_parameters_error(cls, message=None):
        return cls(cls.PARAMETERS_ERROR, message)


class ResponseSuccess:
    SUCCESS = 'Success'

    def __init__(self, value=None):
        self.type = self.SUCCESS
        self.value = value

    def __bool__(self):
        return True
```

{icon: github}
B> Git tag: [chapter-3-responses-and-failures](https://github.com/pycabook/rentomatic/tree/chapter-3-responses-and-failures)

Through the `_format_message()` method we enable the class to accept both string messages and Python exceptions, which is very handy when dealing with external libraries that can raise exceptions we do not know or do not want to manage.

As explained before, the `PARAMETERS_ERROR` type encompasses all those errors that come from an invalid set of parameters, which is the case of this function, that shall be called whenever the request is wrong, which means that some parameters contain errors or are missing.

## Error management in a use case

Our implementation of requests and responses is finally complete, so we can now implement the last version of our use case. The `RoomListUseCase` class is still missing a proper validation of the incoming request.

Let's change the `test_room_list_without_parameters` test in the `tests/use_cases/test_room_list_use_case.py` file, adding `filters=None` to `assert_called_with`, to match the new API

``` python
def test_room_list_without_parameters(domain_rooms):
    repo = mock.Mock()
    repo.list.return_value = domain_rooms

    room_list_use_case = uc.RoomListUseCase(repo)
    request = req.RoomListRequestObject()

    response = room_list_use_case.execute(request)

    assert bool(response) is True
    repo.list.assert_called_with(filters=None)
    assert response.value == domain_rooms
```

There are three new tests that we can add to check the behaviour of the use case when `filters` is not `None`. The first one checks that the value of the `filters` key in the dictionary used to create the request is actually used when calling the repository. These last two tests check the behaviour of the use case when the repository raises an exception or when the request is badly formatted.

``` python
from rentomatic.response_objects import response_objects as res

[...]

def test_room_list_with_filters(domain_rooms):
    repo = mock.Mock()
    repo.list.return_value = domain_rooms

    room_list_use_case = uc.RoomListUseCase(repo)
    qry_filters = {'code__eq': 5}
    request_object = req.RoomListRequestObject.from_dict(
        {'filters': qry_filters})

    response_object = room_list_use_case.execute(request_object)

    assert bool(response_object) is True
    repo.list.assert_called_with(filters=qry_filters)
    assert response_object.value == domain_rooms


def test_room_list_handles_generic_error():
    repo = mock.Mock()
    repo.list.side_effect = Exception('Just an error message')

    room_list_use_case = uc.RoomListUseCase(repo)
    request_object = req.RoomListRequestObject.from_dict({})

    response_object = room_list_use_case.execute(request_object)

    assert bool(response_object) is False
    assert response_object.value == {
        'type': res.ResponseFailure.SYSTEM_ERROR,
        'message': "Exception: Just an error message"
    }


def test_room_list_handles_bad_request():
    repo = mock.Mock()

    room_list_use_case = uc.RoomListUseCase(repo)
    request_object = req.RoomListRequestObject.from_dict({'filters': 5})

    response_object = room_list_use_case.execute(request_object)

    assert bool(response_object) is False
    assert response_object.value == {
        'type': res.ResponseFailure.PARAMETERS_ERROR,
        'message': "filters: Is not iterable"
    }
```

Change the file `rentomatic/use_cases/room_list_use_cases.py` to contain the new use case implementation that makes all the tests pass

``` python
from rentomatic.response_objects import response_objects as res


class RoomListUseCase(object):

    def __init__(self, repo):
        self.repo = repo

    def execute(self, request_object):
        if not request_object:
            return res.ResponseFailure.build_from_invalid_request_object(
                request_object)

        try:
            rooms = self.repo.list(filters=request_object.filters)
            return res.ResponseSuccess(rooms)
        except Exception as exc:
            return res.ResponseFailure.build_system_error(
                "{}: {}".format(exc.__class__.__name__, "{}".format(exc)))
```

{icon: github}
B> Git tag: [chapter-3-error-management-in-a-use-case](https://github.com/pycabook/rentomatic/tree/chapter-3-error-management-in-a-use-case)

As you can see, the first thing that the `execute()` method does is to check if the request is valid. Otherwise, it returns a `ResponseFailure` built with the same request object. Then the actual business logic is implemented, calling the repository and returning a successful response. If something goes wrong in this phase the exception is caught and returned as an aptly formatted `ResponseFailure`.

## Integrating external systems

I want to point out a big problem represented by mocks. As we are testing objects using mocks for external systems, like the repository, no tests fail at the moment, but trying to run the Flask development server would certainly return an error. As a matter of fact, neither the repository nor the HTTP server is in sync with the new API, but this cannot be shown by unit tests if they are properly written. This is the reason why we need integration tests, since the real components are running only at that point, and this can raise issues that were masked by mocks.

For this simple project, my integration test is represented by the Flask development server, which at this point crashes with this exception

``` python
TypeError: execute() missing 1 required positional argument: 'request_object'
```

Actually, after the introduction of requests and responses, we didn't change the REST endpoint, which is one of the connections between the external world and the use case. Given that the API of the use case changed, we surely need to change the endpoint code, which calls the use case.


## The HTTP server

As we can see from the above exception the `execute` method is called with the wrong parameters in the REST endpoint. The new version of `tests/rest/test_get_rooms_list.py` is

``` python
import json
from unittest import mock

from rentomatic.domain.room import Room
from rentomatic.response_objects import response_objects as res

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
    mock_use_case().execute.return_value = res.ResponseSuccess(rooms)

    http_response = client.get('/rooms')

    assert json.loads(http_response.data.decode('UTF-8')) == [room_dict]

    mock_use_case().execute.assert_called()
    args, kwargs = mock_use_case().execute.call_args
    assert args[0].filters == {}

    assert http_response.status_code == 200
    assert http_response.mimetype == 'application/json'


@mock.patch('rentomatic.use_cases.room_list_use_case.RoomListUseCase')
def test_get_with_filters(mock_use_case, client):
    mock_use_case().execute.return_value = res.ResponseSuccess(rooms)

    http_response = client.get('/rooms?filter_price__gt=2&filter_price__lt=6')

    assert json.loads(http_response.data.decode('UTF-8')) == [room_dict]

    mock_use_case().execute.assert_called()
    args, kwargs = mock_use_case().execute.call_args
    assert args[0].filters == {'price__gt': '2', 'price__lt': '6'}

    assert http_response.status_code == 200
    assert http_response.mimetype == 'application/json'
```

The `test_get` function was already present but has been changed to reflect the use of requests and responses. The first change is that the `execute` method in the mock has to return a proper response

``` python
from rentomatic.response_objects import response_objects as res

[...]

def test_get(mock_use_case, client):
    mock_use_case().execute.return_value = res.ResponseSuccess(rooms)
```

and the second is the assertion on the call of the same method. It should be called with a properly formatted request, but since we can't compare requests, we need a way to look into the call arguments. This can be done with

``` python
    mock_use_case().execute.assert_called()
    args, kwargs = mock_use_case().execute.call_args
    assert args[0].filters == {}
```

as `execute` should receive as an argument a request with empty filters. The `test_get_with_filters` function performs the same operation but passing a query string to the `/rooms` URL, which requires a different assertion

``` python
    assert args[0].filters == {'price__gt': '2', 'price__lt': '6'}
```
Both the tests pass with a new version of the `room` endpoint in the `rentomatic/rest/room.py` file

``` python
import json

from flask import Blueprint, request, Response

from rentomatic.repository import memrepo as mr
from rentomatic.use_cases import room_list_use_case as uc
from rentomatic.serializers import room_json_serializer as ser
from rentomatic.request_objects import room_list_request_object as req
from rentomatic.response_objects import response_objects as res

blueprint = Blueprint('room', __name__)

STATUS_CODES = {
    res.ResponseSuccess.SUCCESS: 200,
    res.ResponseFailure.RESOURCE_ERROR: 404,
    res.ResponseFailure.PARAMETERS_ERROR: 400,
    res.ResponseFailure.SYSTEM_ERROR: 500
}

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
    qrystr_params = {
        'filters': {},
    }

    for arg, values in request.args.items():
        if arg.startswith('filter_'):
            qrystr_params['filters'][arg.replace('filter_', '')] = values

    request_object = req.RoomListRequestObject.from_dict(qrystr_params)

    repo = mr.MemRepo([room1, room2, room3])
    use_case = uc.RoomListUseCase(repo)

    response = use_case.execute(request_object)

    return Response(json.dumps(response.value, cls=ser.RoomJsonEncoder),
                    mimetype='application/json',
                    status=STATUS_CODES[response.type])
```

{icon: github}
B> Git tag: [chapter-3-the-http-server](https://github.com/pycabook/rentomatic/tree/chapter-3-the-http-server)

## The repository

If we run the Flask development webserver now and try to access the `/rooms` endpoint, we will get a nice response that says

``` json
{"type": "SystemError", "message": "TypeError: list() got an unexpected keyword argument 'filters'"}
```

and if you look at the HTTP response[^devtools] you can see an HTTP 500 error, which is exactly the mapping of our `SystemError` use case error, which in turn signals a Python exception, which is in the `message` part of the error.

[^devtools]: For example using the browser developer tools. In Chrome, press F12 and open the Network tab, then refresh the page.

This error comes from the repository, which has not been migrated to the new API. We need then to change the `list` method of the `MemRepo` class to accept the `filters` parameter and to act accordingly. The new version of the `tests/repository/test_memrepo.py` file is

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


def test_repository_list_with_code_equal_filter(room_dicts):
    repo = memrepo.MemRepo(room_dicts)

    repo_rooms = repo.list(
        filters={'code__eq': 'fe2c3195-aeff-487a-a08f-e0bdc0ec6e9a'}
    )

    assert len(repo_rooms) == 1
    assert repo_rooms[0].code == 'fe2c3195-aeff-487a-a08f-e0bdc0ec6e9a'


def test_repository_list_with_price_equal_filter(room_dicts):
    repo = memrepo.MemRepo(room_dicts)

    repo_rooms = repo.list(
        filters={'price__eq': 60}
    )

    assert len(repo_rooms) == 1
    assert repo_rooms[0].code == '913694c6-435a-4366-ba0d-da5334a611b2'


def test_repository_list_with_price_less_than_filter(room_dicts):
    repo = memrepo.MemRepo(room_dicts)

    repo_rooms = repo.list(
        filters={'price__lt': 60}
    )

    assert len(repo_rooms) == 2
    assert set([r.code for r in repo_rooms]) ==\
        {
            'f853578c-fc0f-4e65-81b8-566c5dffa35a',
            'eed76e77-55c1-41ce-985d-ca49bf6c0585'
    }


def test_repository_list_with_price_greater_than_filter(room_dicts):
    repo = memrepo.MemRepo(room_dicts)

    repo_rooms = repo.list(
        filters={'price__gt': 48}
    )

    assert len(repo_rooms) == 2
    assert set([r.code for r in repo_rooms]) ==\
        {
            '913694c6-435a-4366-ba0d-da5334a611b2',
            'fe2c3195-aeff-487a-a08f-e0bdc0ec6e9a'
    }


def test_repository_list_with_price_between_filter(room_dicts):
    repo = memrepo.MemRepo(room_dicts)

    repo_rooms = repo.list(
        filters={
            'price__lt': 66,
            'price__gt': 48
        }
    )

    assert len(repo_rooms) == 1
    assert repo_rooms[0].code == '913694c6-435a-4366-ba0d-da5334a611b2'


def test_repository_list_price_as_strings(room_dicts):
    repo = memrepo.MemRepo(room_dicts)

    repo.list(filters={'price__eq': '60'})

    repo.list(filters={'price__lt': '60'})

    repo.list(filters={'price__gt': '60'})
```

As you can see, I added many tests. One test for each of the four accepted filters (`code__eq`, `price__eq`, `price__lt`, `price__gt`, see `rentomatic/request_objects/room_list_request_object.py`), and one final test that tries two different filters at the same time. The new version of the `rentomatic/repository/memrepo.py` file that passes all the tests is

``` python
from rentomatic.domain import room as r


class MemRepo:
    def __init__(self, data):
        self.data = data

    def list(self, filters=None):

        result = [r.Room.from_dict(i) for i in self.data]

        if filters is None:
            return result

        if 'code__eq' in filters:
            result = [r for r in result if r.code == filters['code__eq']]

        if 'price__eq' in filters:
            result = [r for r in result if r.price == int(filters['price__eq'])]

        if 'price__lt' in filters:
            result = [r for r in result if r.price < int(filters['price__lt'])]

        if 'price__gt' in filters:
            result = [r for r in result if r.price > int(filters['price__gt'])]

        return result
```

{icon: github}
B> Git tag: [chapter-3-the-repository](https://github.com/pycabook/rentomatic/tree/chapter-3-the-repository)

At this point, you can fire up the Flask development webserver with `flask run`, and get the list of all your rooms at

```
http://localhost:5000/rooms
```

You can also use filters in the URL, like

```
http://localhost:5000/rooms?filter_code__eq=f853578c-fc0f-4e65-81b8-566c5dffa35a
```

which returns the room with the given code or

```
http://localhost:5000/rooms?filter_price__lt=50
```

which return all the rooms with a price less than 50.

## Conclusions

We now have a very robust system to manage input validation and error conditions, and it is generic enough to be used with any possible use case. Obviously, we are free to add new types of errors to increase the granularity with which we manage failures, but the present version already covers everything that can happen inside a use case.

In the next chapter, we will have a look at repositories based on real database engines, showing how to test external systems with integration tests, and how the clean architecture allows us to simply switch between very different backends for services.

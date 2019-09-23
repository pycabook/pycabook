# Chapter 4 - Database repositories

{icon: quote-right}
B> _Ooooh, I'm very sorry Hans. I didn't get that memo. Maybe you should've put it on the bulletin board._
B> - Die Hard (1988)

The basic in-memory repository I implemented for the project is enough to show the concept of the repository layer abstraction, and any other type of repository will follow the same idea. In the spirit of providing a simple but realistic solution, however, I believe it is worth reimplementing the repository layer with a proper database.

This gives me the chance to show you one of the big advantages of a clean architecture, namely the simplicity with which you can replace existing components with others, possibly based on a completely different technology.

## Introduction

The clean architecture we devised in the previous chapters defines a use case that receives a repository instance as an argument and uses its `list` method to retrieve the contained entries. This allows the use case to form a very loose coupling with the repository, being connected only through the API exposed by the object and not to the real implementation. In other words, the use cases are polymorphic with respect to the `list` method.

This is very important and it is the core of the clean architecture design. Being connected through an API, the use case and the repository can be replaced by different implementations at any time, given that the new implementation provides the requested interface.

It is worth noting, for example, that the initialisation of the object is not part of the API that the use cases are using since the repository is initialised in the main script and not in each use case. The `__init__` method, thus, doesn't need to be the same among the repository implementation, which gives us a great deal of flexibility, as different storages may need different initialisation values.

The simple repository we implemented in one of the previous chapters was

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
            result = [r for r in result if r.price == filters['price__eq']]

        if 'price__lt' in filters:
            result = [r for r in result if r.price < filters['price__lt']]

        if 'price__gt' in filters:
            result = [r for r in result if r.price > filters['price__gt']]

        return result
```

whose interface is made of two parts: the initialisation and the `list` method. The `__init__` method accepts values because this specific object doesn't act as long-term storage, so we are forced to pass some data every time we instantiate the class.

A repository based on a proper database will not need to be filled with data when initialised, its main job being that of storing data between sessions, but will nevertheless need to be initialised at least with the database address and access credentials.

Furthermore, we have to deal with a proper external system, so we have to devise a strategy to test it, as this might require a running database engine in the background. Remember that we are creating a specific implementation of a repository, so everything will be tailored to the actual database system that we will choose.

## A repository based on PostgreSQL

Let's start with a repository based on a popular SQL database, [PostgreSQL](https://www.postgresql.org). It can be accessed from Python in many ways, but the best one is probably through the [SQLAlchemy](https://www.sqlalchemy.org) interface. SQLAlchemy is an ORM, a package that maps objects (as in object-oriented) to a relational database, and can normally be found in web frameworks like Django or in standalone packages like the one we are considering.

The important thing about ORMs is that they are very good examples of something you shouldn't try to mock. Properly mocking the SQLAlchemy structures that are used when querying the DB results in very complex code that is difficult to write and almost impossible to maintain, as every single change in the queries results in a series of mocks that have to be written again.[^query]

[^query]: unless you consider things like `sessionmaker_mock()().query.assert_called_with(Room)` something attractive. And this was by far the simplest mock I had to write.

We need therefore to set up an integration test. The idea is to create the DB, set up the connection with SQLAlchemy, test the condition we need to check, and destroy the database. Since the action of creating and destroying the DB can be expensive in terms of time, we might want to do it just at the beginning and at the end of the whole test suite, but even with this change, the tests will be slow. This is why we will also need to use labels to avoid running them every time we run the suite. Let's face this complex task one step at a time.

### Label integration tests

The first thing we need to do is to label integration tests, exclude them by default and create a way to run them. Since pytest supports labels, called _marks_, we can use this feature to add a global mark to a whole module. Create the `tests/repository/postgres/test_postgresrepo.py` file and put in it this code

``` python
import pytest

pytestmark = pytest.mark.integration


def test_dummy():
    pass
```

The `pytestmark` module attribute labels every test in the module with the `integration` tag. To verify that this works I added a `test_dummy` test function which always passes. You can now run `py.test -svv -m integration` to ask pytest to run only the tests marked with that label. The `-m` option supports a rich syntax that you can learn by reading the [documentation](https://docs.pytest.org/en/latest/example/markers.html).

While this is enough to run integration tests selectively, it is not enough to skip them by default. To do this, we can alter the pytest setup to label all those tests as skipped, but this will give us no means to run them. The standard way to implement this is to define a new command-line option and to process each marked test according to the value of this option.

To do it open the `tests/conftest.py` that we already created and add the following code

``` python
def pytest_addoption(parser):
    parser.addoption("--integration", action="store_true",
                     help="run integration tests")


def pytest_runtest_setup(item):
    if 'integration' in item.keywords and not \
            item.config.getvalue("integration"):
        pytest.skip("need --integration option to run")
```

The first function is a hook into the pytest CLI parser that adds the `--integration` option. When this option is specified on the command line the pytest setup will contain the key `integration` with value `True`.

The second function is a hook into the pytest setup of every single test. The `item` variable contains the test itself (actually a `_pytest.python.Function` object), which in turn contains two useful pieces of information. The first is the `item.keywords` attribute, that contains the test marks, alongside many other interesting things like the name of the test, the file, the module, and also information about the patches that happen inside the test. The second is the `item.config` attribute that contains the parsed pytest command line.

So, if the test is marked with `integration` (`'integration' in item.keywords`) and the `--integration` option is not present (`not item.config.getvalue("integration")`) the test is skipped.

{icon: github}
B> Git tag: [chapter-4-label-integration-tests](https://github.com/pycabook/rentomatic/tree/chapter-4-label-integration-tests)

### Create the SQLalchemy classes

Creating and populating the test database with initial data will be part of the test suite, but we need to define somewhere the tables that will be contained in the database. This is where SQLAlchemy's ORM comes into play, as we will define those tables in terms of Python objects.

Add the packages `SQLAlchemy` to the `prod.txt` requirements file and update the installed packages with

``` sh
$ pip install -r requirements/dev.txt
```

Create the `rentomatic/repository/postgres_objects.py` file with the following content

``` python
from sqlalchemy import Column, Integer, String, Float
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()


class Room(Base):
    __tablename__ = 'room'

    id = Column(Integer, primary_key=True)

    code = Column(String(36), nullable=False)
    size = Column(Integer)
    price = Column(Integer)
    longitude = Column(Float)
    latitude = Column(Float)
```

Let's comment it section by section

``` python
from sqlalchemy import Column, Integer, String, Float
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()
```

We need to import many things from the SQLAlchemy package to set up the database and to create the table. Remember that SQLAlchemy has a declarative approach, so we need to instantiate the `Base` object and then use it as a starting point to declare the tables/objects.

``` python
class Room(Base):
    __tablename__ = 'room'

    id = Column(Integer, primary_key=True)

    code = Column(String(36), nullable=False)
    size = Column(Integer)
    price = Column(Integer)
    longitude = Column(Float)
    latitude = Column(Float)
```

This is the class that represents the `Room` in the database. It is important to understand that this is not the class we are using in the business logic, but the class that we want to map into the SQL database. The structure of this class is thus dictated by the needs of the storage layer, and not by the use cases. You might want for instance to store `longitude` and `latitude` in a JSON field, to allow for easier extendibility, without changing the definition of the domain model. In the simple case of the Rent-o-matic project, the two classes almost overlap, but this is not the case generally speaking.

Obviously, this means that you have to keep the storage and the domain levels in sync and that you need to manage migrations on your own. You can use tools like Alembic, but the migrations will not come directly from domain model changes.

{icon: github}
B> Git tag: [chapter-4-create-the-sqlalchemy-classes](https://github.com/pycabook/rentomatic/tree/chapter-4-create-the-sqlalchemy-classes)

### Spin up and tear down the database container

When we run the integration tests the Postgres database engine must be already running in the background, and it must be already configured, for example, with a pristine database ready to be used. Moreover, when all the tests have been executed the database should be removed and the database engine stopped.

This is a perfect job for Docker, which can run complex systems in isolation with minimal configuration. We might orchestrate the creation and destruction of the database with bash, but this would mean wrapping the test suite in another script which is not my favourite choice.

The structure that I show you here makes use of docker-compose through the `pytest-docker`, `pyyaml`, and `sqlalchemy-utils` packages. The idea is simple: given the configuration of the database (name, user, password), we create a temporary file containing the docker-compose configuration that spins up a Postgres database. Once the Docker container is running, we connect to the database engine with SQLAlchemy to create the database we will use for the tests and we populate it. When all the tests have been executed we tear down the Docker image and we leave the system in a clean status.

Due to the complexity of the problem and a limitation of the `pytest-docker` package, the resulting setup is a bit convoluted. The `pytest-docker` plugin requires you to create a `docker_compose_file` fixture that should return the path of a file with the docker-compose configuration (YAML syntax). The plugin provides two fixtures, `docker_ip` and `docker_services`: the first one is simply the IP of the Docker host (which can be different from localhost in case of remote execution) while the second is the actual routine that runs the containers through docker-compose and stops them after the test session. My setup to run this plugin is complex, but it allows me to keep all the database information in a single place.

The first fixture goes in `tests/conftest.py` and contains the information about the PostgreSQL connection, namely the host, the database name, the user name, and the password

``` python
@pytest.fixture(scope='session')
def docker_setup(docker_ip):
    return {
        'postgres': {
            'dbname': 'rentomaticdb',
            'user': 'postgres',
            'password': 'rentomaticdb',
            'host': docker_ip
        }
    }
```

This way I have a single source of parameters that I will use to spin up the Docker container, but also to set up the connection with the container itself during the tests.

The other two fixtures in the same file are the one that creates a temporary file and a one that creates the configuration for docker-compose and stores it in the previously created file.

``` python
import os
import tempfile
import yaml

[...]

@pytest.fixture(scope='session')
def docker_tmpfile():
    f = tempfile.mkstemp()
    yield f
    os.remove(f[1])


@pytest.fixture(scope='session')
def docker_compose_file(docker_tmpfile, docker_setup):
    content = {
        'version': '3.1',
        'services': {
            'postgresql': {
                'restart': 'always',
                'image': 'postgres',
                'ports': ["5432:5432"],
                'environment': [
                    'POSTGRES_PASSWORD={}'.format(
                        docker_setup['postgres']['password']
                    )
                ]
            }
        }
    }

    f = os.fdopen(docker_tmpfile[0], 'w')
    f.write(yaml.dump(content))
    f.close()

    return docker_tmpfile[1]
```

The `pytest-docker` plugin leaves to us the task of defining a function to check if the container is responsive, as the way to do it depends on the actual system that we are running (in this case PostgreSQL). I also have to define the final fixture related to docker-compose, which makes use of all I defined previously to create a connection with the PostgreSQL database. Both fixtures are defined in `tests/repository/postgres/conftest.py`

``` python
import psycopg2
import sqlalchemy
import sqlalchemy_utils

import pytest


def pg_is_responsive(ip, docker_setup):
    try:
        conn = psycopg2.connect(
            "host={} user={} password={} dbname={}".format(
                ip,
                docker_setup['postgres']['user'],
                docker_setup['postgres']['password'],
                'postgres'
            )
        )
        conn.close()
        return True
    except psycopg2.OperationalError as exp:
        return False


@pytest.fixture(scope='session')
def pg_engine(docker_ip, docker_services, docker_setup):
    docker_services.wait_until_responsive(
        timeout=30.0, pause=0.1,
        check=lambda: pg_is_responsive(docker_ip, docker_setup)
    )

    conn_str = "postgresql+psycopg2://{}:{}@{}/{}".format(
        docker_setup['postgres']['user'],
        docker_setup['postgres']['password'],
        docker_setup['postgres']['host'],
        docker_setup['postgres']['dbname']
    )
    engine = sqlalchemy.create_engine(conn_str)
    sqlalchemy_utils.create_database(engine.url)

    conn = engine.connect()

    yield engine

    conn.close()
```

As you can see, the `pg_is_responsive` function relies on a setup dictionary like the one that we defined in the `docker_setup` fixture (the input argument is aptly named the same way) and returns a boolean after having checked if it is possible to establish a connection with the server.

The second fixture receives `docker_services`, which spins up docker-compose automatically using the `docker_compose_file` fixture I defined previously. The `pg_is_responsive` function is used to wait for the container to reach a running state, then a connection is established and the database is created. To simplify this last operation I imported and used the package `sqlalchemy_utils`. The fixture yields the SQLAlchemy `engine` object, so it can be correctly closed once the session is finished.

To properly run these fixtures we need to add some requirements. The new `requirements/test.txt` file is

``` text
-r prod.txt
tox
coverage
pytest
pytest-cov
pytest-flask
pytest-docker
docker-compose
pyyaml
psycopg2
sqlalchemy_utils
```

Remember to run `pip` again to actually install the requirements after you edited the file

``` sh
$ pip install -r requirements/dev.txt
```

{icon: github}
B> Git tag: [chapter-4-the-database-container](https://github.com/pycabook/rentomatic/tree/chapter-4-the-database-container)

### Database fixtures

With the `pg_engine` fixture we can define higher-level functions such as `pg_session_empty` that gives us access to the pristine database, `pg_data`, which defines some values for the test queries, and `pg_session` that creates the rows of the `Room` table using the previous two fixtures. All these fixtures will be defined in `tests/repository/postgres/conftest.py`

``` python
from rentomatic.repository.postgres_objects import Base, Room

[...]

@pytest.fixture(scope='session')
def pg_session_empty(pg_engine):
    Base.metadata.create_all(pg_engine)

    Base.metadata.bind = pg_engine

    DBSession = sqlalchemy.orm.sessionmaker(bind=pg_engine)

    session = DBSession()

    yield session

    session.close()


@pytest.fixture(scope='function')
def pg_data():
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


@pytest.fixture(scope='function')
def pg_session(pg_session_empty, pg_data):
    for r in pg_data:
        new_room = Room(
            code=r['code'],
            size=r['size'],
            price=r['price'],
            longitude=r['longitude'],
            latitude=r['latitude']
        )
        pg_session_empty.add(new_room)
        pg_session_empty.commit()

    yield pg_session_empty

    pg_session_empty.query(Room).delete()
```

Note that this last fixture has a `function` scope, thus it is run for every test. Therefore, we delete all rooms after the yield returns, leaving the database in the same state it had before the test. This is not strictly necessary in this particular case, as during the tests we are only reading from the database, so we might add the rooms at the beginning of the test session and just destroy the container at the end of it. This doesn't generally work, however, such as when tests add entries to the database, so I preferred to show you a more generic solution.

We can test this whole setup changing the `test_dummy` function so that it fetches all the rows of the `Room` table and verifying that the query returns 4 values.

The new version of `tests/repository/postgres/test_postgresrepo.py` is 

``` python
import pytest
from rentomatic.repository.postgres_objects import Room

pytestmark = pytest.mark.integration


def test_dummy(pg_session):
    assert len(pg_session.query(Room).all()) == 4
```

{icon: github}
B> Git tag: [chapter-4-database-fixtures](https://github.com/pycabook/rentomatic/tree/chapter-4-database-fixtures)

### Integration tests

At this point we can create the real tests in the `tests/repository/postgres/test_postgresrepo.py` file, replacing the `test_dummy` one. The first function is `test_repository_list_without_parameters`, which runs the `list` method without any argument. The test receives the `docker_setup` fixture that allows us to initialise the `PostgresRepo` class, the `pg_data` fixture with the test data that we put in the database, and the `pg_session` fixture that creates the actual test database in the background. The actual test code compares the codes of the rooms returned by the `list` method and the test data of the `pg_data` fixture.

The file is basically a copy of `tests/repository/postgres/test_memrepo.py`, which is not surprising. Usually, you want to test the very same conditions, whatever the storage system. Towards the end of the chapter we will see, however, that while these files are initially the same, they can evolve differently as we find bugs or corner cases that come from the specific implementation (in-memory storage, PostgreSQL, and so on).

``` python
import pytest

from rentomatic.repository import postgresrepo

pytestmark = pytest.mark.integration


def test_repository_list_without_parameters(
        docker_setup, pg_data, pg_session):
    repo = postgresrepo.PostgresRepo(docker_setup['postgres'])

    repo_rooms = repo.list()

    assert set([r.code for r in repo_rooms]) == \
        set([r['code'] for r in pg_data])
```

The rest of the test suite is basically doing the same. Each test creates the PostgresRepo object, it runs its `list` method with a given value of the `filters` argument, and compares the actual result with the expected one.

``` python
def test_repository_list_with_code_equal_filter(
        docker_setup, pg_data, pg_session):
    repo = postgresrepo.PostgresRepo(docker_setup['postgres'])

    repo_rooms = repo.list(
        filters={'code__eq': 'fe2c3195-aeff-487a-a08f-e0bdc0ec6e9a'}
    )

    assert len(repo_rooms) == 1
    assert repo_rooms[0].code == 'fe2c3195-aeff-487a-a08f-e0bdc0ec6e9a'


def test_repository_list_with_price_equal_filter(
        docker_setup, pg_data, pg_session):
    repo = postgresrepo.PostgresRepo(docker_setup['postgres'])

    repo_rooms = repo.list(
        filters={'price__eq': 60}
    )

    assert len(repo_rooms) == 1
    assert repo_rooms[0].code == '913694c6-435a-4366-ba0d-da5334a611b2'


def test_repository_list_with_price_less_than_filter(
        docker_setup, pg_data, pg_session):
    repo = postgresrepo.PostgresRepo(docker_setup['postgres'])

    repo_rooms = repo.list(
        filters={'price__lt': 60}
    )

    assert len(repo_rooms) == 2
    assert set([r.code for r in repo_rooms]) ==\
        {
            'f853578c-fc0f-4e65-81b8-566c5dffa35a',
            'eed76e77-55c1-41ce-985d-ca49bf6c0585'
    }


def test_repository_list_with_price_greater_than_filter(
        docker_setup, pg_data, pg_session):
    repo = postgresrepo.PostgresRepo(docker_setup['postgres'])

    repo_rooms = repo.list(
        filters={'price__gt': 48}
    )

    assert len(repo_rooms) == 2
    assert set([r.code for r in repo_rooms]) ==\
        {
            '913694c6-435a-4366-ba0d-da5334a611b2',
            'fe2c3195-aeff-487a-a08f-e0bdc0ec6e9a'
    }


def test_repository_list_with_price_between_filter(
        docker_setup, pg_data, pg_session):
    repo = postgresrepo.PostgresRepo(docker_setup['postgres'])

    repo_rooms = repo.list(
        filters={
            'price__lt': 66,
            'price__gt': 48
        }
    )

    assert len(repo_romos) == 1
    assert repo_rooms[0].code == '913694c6-435a-4366-ba0d-da5334a611b2'
```

Remember that I introduced these tests one at a time and that I'm not showing you the full TDD workflow only for brevity's sake. The code of the `PostgresRepo` class has been developed following a strict TDD approach, and I recommend you to do the same. The resulting code goes in `rentomatic/repository/postgresrepo.py`, the same directory we created the `postgres_objects.py` file.

``` python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from rentomatic.domain import room
from rentomatic.repository.postgres_objects import Base, Room


class PostgresRepo:
    def __init__(self, connection_data):
        connection_string = "postgresql+psycopg2://{}:{}@{}/{}".format(
            connection_data['user'],
            connection_data['password'],
            connection_data['host'],
            connection_data['dbname']
        )

        self.engine = create_engine(connection_string)
        Base.metadata.bind = self.engine

    def _create_room_objects(self, results):
        return [
            room.Room(
                code=q.code,
                size=q.size,
                price=q.price,
                latitude=q.latitude,
                longitude=q.longitude
            )
            for q in results
        ]

    def list(self, filters=None):
        DBSession = sessionmaker(bind=self.engine)
        session = DBSession()

        query = session.query(Room)

        if filters is None:
            return self._create_room_objects(query.all())

        if 'code__eq' in filters:
            query = query.filter(Room.code == filters['code__eq'])

        if 'price__eq' in filters:
            query = query.filter(Room.price == filters['price__eq'])

        if 'price__lt' in filters:
            query = query.filter(Room.price < filters['price__lt'])

        if 'price__gt' in filters:
            query = query.filter(Room.price > filters['price__gt'])

        return self._create_room_objects(query.all())
```

{icon: github}
B> Git tag: [chapter-4-integration-tests](https://github.com/pycabook/rentomatic/tree/chapter-4-integration-tests)

I opted for a very simple solution with multiple `if` statements, but if this was a real-world project the `list` method would require a smarter solution to manage a richer set of filters. This class is a good starting point, however, as it passes the whole tests suite. Note that the `list` method returns domain models, which is allowed as the repository is implemented in one of the outer layers of the architecture.

### Running the web server

Now that the whole test suite passes we can run the Flask web server using a PostgreSQL container. This is not yet a production scenario, but I will not cover that part of the setup, as it belongs to a different area of expertise. It will be sufficient to point out that the Flask development web server cannot sustain big loads, and that a database run in a container will lose all the data when the container is stopped. A production infrastructure will probably run a WSGI server like uWSGI or Gunicorn ([here](https://wsgi.readthedocs.io/en/latest/servers.html) you can find a curated list of WSGI servers) and a proper database like an AWS RDS instance.

This section, however, shows you how the components we created work together, and even though the tools used are not powerful enough for a real production case, the whole architecture is exactly the same that you would use to provide a service to real users.

The first thing to do is to run PostgreSQL in Docker manually

``` sh
docker run --name rentomatic -e POSTGRES_PASSWORD=rentomaticdb -p 5432:5432 -d postgres
```

This executes the `postgres` image in a container named `rentomatic`, setting the environment variable `POSTGRES_PASSWORD` to `rentomaticdb`. The container maps the standard PostgreSQL port 5432 to the same port in the host and runs in detached mode (leaving the terminal free).

You can verify that the container is properly running trying to connect with `psql`

``` sh
docker run -it --rm --link rentomatic:rentomatic postgres psql -h rentomatic -U postgres
Password for user postgres: 
psql (11.1 (Debian 11.1-1.pgdg90+1))
Type "help" for help.

postgres=# 
```

Check the [Docker documentation](https://docs.docker.com/engine/reference/run/) and the [PostgreSQL image documentation](https://hub.docker.com/_/postgres/) to get a better understanding of all the flags used in this command line. The password asked is the one set previously with the `POSTGRES_PASSWORD` environment variable.

Now create the `initial_postgres_setup.py` file in the main directory of the project (alongside `wsgi.py`)

``` python
import sqlalchemy
import sqlalchemy_utils

from rentomatic.repository.postgres_objects import Base, Room

setup = {
    'dbname': 'rentomaticdb',
    'user': 'postgres',
    'password': 'rentomaticdb',
    'host': 'localhost'
}

conn_str = "postgresql+psycopg2://{}:{}@{}/{}".format(
    setup['user'],
    setup['password'],
    setup['host'],
    setup['dbname']
)

engine = sqlalchemy.create_engine(conn_str)
sqlalchemy_utils.create_database(engine.url)
conn = engine.connect()

Base.metadata.create_all(engine)
Base.metadata.bind = engine
DBSession = sqlalchemy.orm.sessionmaker(bind=engine)
session = DBSession()


data = [
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

for r in data:
    new_room = Room(
        code=r['code'],
        size=r['size'],
        price=r['price'],
        longitude=r['longitude'],
        latitude=r['latitude']
    )
    session.add(new_room)
    session.commit()
```

As you can see, this file is basically a collection of what we already did in some of the fixtures. This is not surprising, as the fixtures simulated the creation of a production database for each test. This file, however, is meant to be run only once, at the very beginning of the life of the database.

We are ready to configure the database, then. Run the Postgres initialization

``` sh
$ python initial_postgres_setup.py
```

and then you can verify that everything worked connecting again to the PostgreSQL with `psql`. If you are not familiar with the tool you can find the description of the commands in the [documentation](https://www.postgresql.org/docs/current/app-psql.html)

``` sh
$ docker run -it --rm --link rentomatic:rentomatic postgres psql -h rentomatic -U postgres
Password for user postgres: 
psql (11.1 (Debian 11.1-1.pgdg90+1))
Type "help" for help.

postgres=# \c rentomaticdb 
You are now connected to database "rentomaticdb" as user "postgres".
rentomaticdb=# \dt
        List of relations
 Schema | Name | Type  |  Owner   
--------+------+-------+----------
 public | room | table | postgres
(1 row)

rentomaticdb=# select * from room;
 id |                 code                 | size | price |  longitude  |  latitude 
----+--------------------------------------+------+-------+-------------+------------
  1 | f853578c-fc0f-4e65-81b8-566c5dffa35a |  215 |    39 | -0.09998975 | 51.75436293
  2 | fe2c3195-aeff-487a-a08f-e0bdc0ec6e9a |  405 |    66 |  0.18228006 | 51.74640997
  3 | 913694c6-435a-4366-ba0d-da5334a611b2 |   56 |    60 |  0.27891577 | 51.45994069
  4 | eed76e77-55c1-41ce-985d-ca49bf6c0585 |   93 |    48 |  0.33894476 | 51.39916678
(4 rows)

rentomaticdb=# 
```

The last thing to do is to change the Flask app, in order to make it connect to the Postgres database using the `PostgresRepo` class instead of using the `MemRepo` one. The new version of the `rentomatic/rest/room.py` is

``` python
import json

from flask import Blueprint, request, Response

from rentomatic.repository import postgresrepo as pr
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

connection_data = {
    'dbname': 'rentomaticdb',
    'user': 'postgres',
    'password': 'rentomaticdb',
    'host': 'localhost'
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

    repo = pr.PostgresRepo(connection_data)
    use_case = uc.RoomListUseCase(repo)

    response = use_case.execute(request_object)

    return Response(json.dumps(response.value, cls=ser.RoomJsonEncoder),
                    mimetype='application/json',
                    status=STATUS_CODES[response.type])
```

Apart from the import and the definition of the connection data, the only line we have to change is

``` python
    repo = mr.MemRepo([room1, room2, room3])
```

which becomes

``` python
    repo = pr.PostgresRepo(connection_data)
```

Now you can run the Flask development server with `flask run` and connect to

```
http://localhost:5000/rooms
```

to test the whole system. 

{icon: github}
B> Git tag: [chapter-4-running-the-web-server](https://github.com/pycabook/rentomatic/tree/chapter-4-running-the-web-server)

## A repository based on MongoDB

Thanks to the flexibility of clean architecture, providing support for multiple storage systems is a breeze. In this section, I will implement the `MongoRepo` class that provides an interface towards MongoDB, a well-known NoSQL database. We will follow the same testing strategy we used for PostgreSQL, with a Docker container that runs the database and docker-compose that orchestrates the spin up and tear down of the whole system.

You will quickly understand the benefits of the complex test structure that I created in the previous section. That structure allows me to reuse some of the fixtures now that I want to implement tests for a new storage system.

Let's start defining the `tests/repository/mongodb/conftest.py` file, which contains the following code

``` python
import pymongo
import pytest


def mg_is_responsive(ip, docker_setup):
    try:
        client = pymongo.MongoClient(
            host=docker_setup['mongo']['host'],
            username=docker_setup['mongo']['user'],
            password=docker_setup['mongo']['password'],
            authSource='admin'
        )
        client.admin.command('ismaster')
        return True
    except pymongo.errors.ServerSelectionTimeoutError:
        return False


@pytest.fixture(scope='session')
def mg_client(docker_ip, docker_services, docker_setup):
    docker_services.wait_until_responsive(
        timeout=30.0, pause=0.1,
        check=lambda: mg_is_responsive(docker_ip, docker_setup)
    )

    client = pymongo.MongoClient(
        host=docker_setup['mongo']['host'],
        username=docker_setup['mongo']['user'],
        password=docker_setup['mongo']['password'],
        authSource='admin'
    )

    yield client

    client.close()


@pytest.fixture(scope='session')
def mg_database_empty(mg_client, docker_setup):
    db = mg_client[docker_setup['mongo']['dbname']]

    yield db

    mg_client.drop_database(docker_setup['mongo']['dbname'])


@pytest.fixture(scope='function')
def mg_data():
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


@pytest.fixture(scope='function')
def mg_database(mg_database_empty, mg_data):
    collection = mg_database_empty.rooms

    collection.insert_many(mg_data)

    yield mg_database_empty

    collection.delete_many({})
```

As you can see these functions are very similar to the ones that we defined for Postgres. The `mg_is_responsive` function is tasked with monitoring the MongoDB container and return True when this latter is ready. The specific way to do this is different from the one employed for PostgreSQL, as these are solutions tailored to the specific technology. The `mg_client` function is similar to the `pg_engine` developed for PostgreSQL, and the same happens for `mg_database_empty`, `mg_data`, and `mg_database`. While the SQLAlchemy package works through a session, PyMongo library creates a client and uses it directly, but the overall structure is the same.

Since we are importing the PyMongo library, remember to add `pymongo` to the `requirements/prod.txt` file and run `pip` again. We need to change the `tests/repository/conftest.py` to add the configuration of the MongoDB container. Unfortunately, due to a limitation of the `pytest-docker` package, it is impossible to define multiple versions of `docker_compose_file`, so we need to add the MongoDB configuration alongside the PostgreSQL one. The `docker_setup` fixture becomes

``` python
@pytest.fixture(scope='session')
def docker_setup(docker_ip):
    return {
        'mongo': {
            'dbname': 'rentomaticdb',
            'user': 'root',
            'password': 'rentomaticdb',
            'host': docker_ip
        },
        'postgres': {
            'dbname': 'rentomaticdb',
            'user': 'postgres',
            'password': 'rentomaticdb',
            'host': docker_ip
        }
    }
```

While the new version of the `docker_compose_file` fixture is

``` python
@pytest.fixture(scope='session')
def docker_compose_file(docker_tmpfile, docker_setup):
    content = {
        'version': '3.1',
        'services': {
            'postgresql': {
                'restart': 'always',
                'image': 'postgres',
                'ports': ["5432:5432"],
                'environment': [
                    'POSTGRES_PASSWORD={}'.format(
                        docker_setup['postgres']['password']
                    )
                ]
            },
            'mongo': {
                'restart': 'always',
                'image': 'mongo',
                'ports': ["27017:27017"],
                'environment': [
                    'MONGO_INITDB_ROOT_USERNAME={}'.format(
                        docker_setup['mongo']['user']
                    ),
                    'MONGO_INITDB_ROOT_PASSWORD={}'.format(
                        docker_setup['mongo']['password']
                    )
                ]
            }
        }
    }

    f = os.fdopen(docker_tmpfile[0], 'w')
    f.write(yaml.dump(content))
    f.close()

    return docker_tmpfile[1]
```

{icon: github}
B> Git tag: [chapter-4-a-repository-based-on-mongodb-step-1](https://github.com/pycabook/rentomatic/tree/chapter-4-a-repository-based-on-mongodb-step-1)

As you can see, setting up MongoDB is not that different from PostgreSQL. Both systems are databases, and the way you connect to them is similar, at least in a testing environment, where you don't need specific settings for the engine.

With the above fixtures, we can write the `MongoRepo` class following TDD.
The `tests/repository/mongodb/test_mongorepo.py` file contains all the tests for this class

``` python
import pytest
from rentomatic.repository import mongorepo

pytestmark = pytest.mark.integration


def test_repository_list_without_parameters(
        docker_setup, mg_data, mg_database):
    repo = mongorepo.MongoRepo(docker_setup['mongo'])

    repo_rooms = repo.list()

    assert set([r.code for r in repo_rooms]) == \
        set([r['code'] for r in mg_data])


def test_repository_list_with_code_equal_filter(
        docker_setup, mg_data, mg_database):
    repo = mongorepo.MongoRepo(docker_setup['mongo'])

    repo_rooms = repo.list(
        filters={'code__eq': 'fe2c3195-aeff-487a-a08f-e0bdc0ec6e9a'}
    )

    assert len(repo_rooms) == 1
    assert repo_rooms[0].code == 'fe2c3195-aeff-487a-a08f-e0bdc0ec6e9a'


def test_repository_list_with_price_equal_filter(
        docker_setup, mg_data, mg_database):
    repo = mongorepo.MongoRepo(docker_setup['mongo'])

    repo_rooms = repo.list(
        filters={'price__eq': 60}
    )

    assert len(repo_rooms) == 1
    assert repo_rooms[0].code == '913694c6-435a-4366-ba0d-da5334a611b2'


def test_repository_list_with_price_less_than_filter(
        docker_setup, mg_data, mg_database):
    repo = mongorepo.MongoRepo(docker_setup['mongo'])

    repo_rooms = repo.list(
        filters={'price__lt': 60}
    )

    assert len(repo_rooms) == 2
    assert set([r.code for r in repo_rooms]) ==\
        {
            'f853578c-fc0f-4e65-81b8-566c5dffa35a',
            'eed76e77-55c1-41ce-985d-ca49bf6c0585'
    }


def test_repository_list_with_price_greater_than_filter(
        docker_setup, mg_data, mg_database):
    repo = mongorepo.MongoRepo(docker_setup['mongo'])

    repo_rooms = repo.list(
        filters={'price__gt': 48}
    )

    assert len(repo_rooms) == 2
    assert set([r.code for r in repo_rooms]) ==\
        {
            '913694c6-435a-4366-ba0d-da5334a611b2',
            'fe2c3195-aeff-487a-a08f-e0bdc0ec6e9a'
    }


def test_repository_list_with_price_between_filter(
        docker_setup, mg_data, mg_database):
    repo = mongorepo.MongoRepo(docker_setup['mongo'])

    repo_rooms = repo.list(
        filters={
            'price__lt': 66,
            'price__gt': 48
        }
    )

    assert len(repo_rooms) == 1
    assert repo_rooms[0].code == '913694c6-435a-4366-ba0d-da5334a611b2'


def test_repository_list_with_price_as_string(
        docker_setup, mg_data, mg_database):
    repo = mongorepo.MongoRepo(docker_setup['mongo'])

    repo_rooms = repo.list(
        filters={
            'price__lt': '60'
        }
    )

    assert len(repo_rooms) == 2
    assert set([r.code for r in repo_rooms]) ==\
        {
            'f853578c-fc0f-4e65-81b8-566c5dffa35a',
            'eed76e77-55c1-41ce-985d-ca49bf6c0585'
    }
```

These tests obviously mirror the tests written for Postgres, as the Mongo interface has to provide the very same API. Actually, since the initialization of the `MongoRepo` class doesn't differ from the initialization of the `PostgresRepo` one, the test suite is exactly the same.

I added a test called `test_repository_list_with_price_as_string` that checks what happens when the price in the filter is expressed as a string. Experimenting with the MongoDB shell I found that in this case, the query wasn't working, so I included the test to be sure the implementation didn't forget to manage this condition.

The `MongoRepo` class is obviously not the same as the Postgres interface, as the PyMongo library is different from SQLAlchemy, and the structure of a NoSQL database differs from the one of a relational one. The file `rentomatic/repository/mongorepo.py` is

``` python
import pymongo

from rentomatic.domain.room import Room


class MongoRepo:
    def __init__(self, connection_data):
        client = pymongo.MongoClient(
            host=connection_data['host'],
            username=connection_data['user'],
            password=connection_data['password'],
            authSource='admin'
        )

        self.db = client[connection_data['dbname']]

    def list(self, filters=None):
        collection = self.db.rooms

        if filters is None:
            result = collection.find()
        else:
            mongo_filter = {}
            for key, value in filters.items():
                key, operator = key.split('__')

                filter_value = mongo_filter.get(key, {})

                if key == 'price':
                    value = int(value)

                filter_value['${}'.format(operator)] = value
                mongo_filter[key] = filter_value

            result = collection.find(mongo_filter)

        return [Room.from_dict(d) for d in result]
```

which makes use of the similarity between the filters of the Rent-o-matic project and the ones of the MongoDB system[^similar].

[^similar]: The similitude between the two systems is not accidental, as I was studying MongoDB at the time I wrote the first article about clean architectures, so I was obviously influenced by it.

{icon: github}
B> Git tag: [chapter-4-a-repository-based-on-mongodb-step-2](https://github.com/pycabook/rentomatic/tree/chapter-4-a-repository-based-on-mongodb-step-2)

At this point we can follow the same steps we did for Postgres, that is creating a stand-alone MongoDB container, filling it with real data, changing the REST endpoint to use `MongoRepo` and run the Flask web server.

To create a MongoDB container you can run this Docker command line

``` sh
$ docker run --name rentomatic -e MONGO_INITDB_ROOT_USERNAME=root -e MONGO_INITDB_ROOT_PASSWORD=rentomaticdb -p 27017:27017 -d mongo
```

To check the connectivity you may run the MongoDB shell in the same container (then exit with Ctrl-D)

``` txt
$ docker exec -it rentomatic mongo --port 27017 -u "root" -p "rentomaticdb" --authenticationDatabase "admin"
MongoDB shell version v4.0.4
connecting to: mongodb://127.0.0.1:27017/
Implicit session: session { "id" : UUID("44f615e3-ec0b-4a16-8b58-f0ae1c48c187") }
MongoDB server version: 4.0.4
>
```

The initialisation file is similar to the one I created for PostgreSQL, and like that one, it borrows code from the fixtures that run in the test suite. The file is named `initial_mongo_setup.py` and is saved in the main project directory.

``` python
import pymongo

setup = {
    'dbname': 'rentomaticdb',
    'user': 'root',
    'password': 'rentomaticdb',
    'host': 'localhost'
}

client = pymongo.MongoClient(
    host=setup['host'],
    username=setup['user'],
    password=setup['password'],
    authSource='admin'
)

db = client[setup['dbname']]

data = [
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

collection = db.rooms

collection.insert_many(data)
```

After you save it, run it with

``` sh
$ python initial_mongo_setup.py
```

If you want to check what happened in the database you can connect again to the container and run a manual query that should return 4 rooms

``` txt
$ docker exec -it rentomatic mongo --port 27017 -u "root" -p "rentomaticdb" --authenticationDatabase "admin"
MongoDB shell version v4.0.4
connecting to: mongodb://127.0.0.1:27017/
Implicit session: session { "id" : UUID("44f615e3-ec0b-4a16-8b58-f0ae1c48c187") }
MongoDB server version: 4.0.4
> use rentomaticdb
switched to db rentomaticdb
> db.rooms.find({})
{ "_id" : ObjectId("5c123219a9a0ca3e85ab34b8"), "code" : "f853578c-fc0f-4e65-81b8-566c5dffa35a", "size" : 215, "price" : 39, "longitude" : -0.09998975, "latitude" : 51.75436293 }
{ "_id" : ObjectId("5c123219a9a0ca3e85ab34b9"), "code" : "fe2c3195-aeff-487a-a08f-e0bdc0ec6e9a", "size" : 405, "price" : 66, "longitude" : 0.18228006, "latitude" : 51.74640997 }
{ "_id" : ObjectId("5c123219a9a0ca3e85ab34ba"), "code" : "913694c6-435a-4366-ba0d-da5334a611b2", "size" : 56, "price" : 60, "longitude" : 0.27891577, "latitude" : 51.45994069 }
{ "_id" : ObjectId("5c123219a9a0ca3e85ab34bb"), "code" : "eed76e77-55c1-41ce-985d-ca49bf6c0585", "size" : 93, "price" : 48, "longitude" : 0.33894476, "latitude" : 51.39916678 }
```

The last step is to modify the `rentomatic/rest/room.py` file to make it use the `MongoRepo` class. The new version of the file is

``` python
import json

from flask import Blueprint, request, Response

from rentomatic.repository import mongorepo as mr
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

connection_data = {
    'dbname': 'rentomaticdb',
    'user': 'root',
    'password': 'rentomaticdb',
    'host': 'localhost'
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

    repo = mr.MongoRepo(connection_data)
    use_case = uc.RoomListUseCase(repo)

    response = use_case.execute(request_object)

    return Response(json.dumps(response.value, cls=ser.RoomJsonEncoder),
                    mimetype='application/json',
                    status=STATUS_CODES[response.type])
```

but the actual changes are

``` diff
-from rentomatic.repository import postgresrepo as pr
+from rentomatic.repository import mongorepo as mr
[...]
-    'user': 'postgres',
+    'user': 'root',
[...]
-    repo = pr.PostgresRepo(connection_data)
+    repo = mr.MongoRepo(connection_data)
```

Please note that the second difference is due to choices in the database configuration, so the relevant changes are only two. This is what you can achieve with a well-decoupled architecture. As I said in the introduction, this might be overkill for some applications, but if you want to provide support for multiple database backends this is definitely one of the best ways to achieve it.

If you run now the Flask development server with `flask run`, and head to

```
http://localhost:5000/rooms
```

you will receive the very same result that the interface based on Postgres was returning.

{icon: github}
B> Git tag: [chapter-4-a-repository-based-on-mongodb-step-3](https://github.com/pycabook/rentomatic/tree/chapter-4-a-repository-based-on-mongodb-step-3)

## Conclusions

This chapter concludes the overview of the clean architecture example. Starting from scratch, we created domain models, serializers, use cases, an in-memory storage system, a command-line interface and an HTTP endpoint. We then improved the whole system with a very generic request/response management code, that provides robust support for errors. Last, we implemented two new storage systems, using both a relational and a NoSQL database.

This is by no means a little achievement. Our architecture covers a very small use case, but is robust and fully tested. Whatever error we might find in the way we dealt with data, databases, requests, and so on, can be isolated and tamed much faster than in a system which doesn't have tests. Moreover, the decoupling philosophy not only allows us to provide support for multiple storage systems, but also to quickly implement new access protocols, or new serialisations for our objects.

# Setup a Python Project

{icon: quote-right}
B> _Snakes. Why did it have to be snakes?_
B> - Raiders of the Lost Ark (1981)

## Virtual environments

One of the first things you have to learn as a Python programmer is how to create, manage, and use your virtual environments. A virtual environment is just a directory (with many subdirectories) that mirrors a Python installation like the one that you can find in your operating system. This is a good way to isolate a specific version of Python and the packages that are not part of the standard library.

This is handy for many reasons. First of all, the Python version installed system-wide (your Linux distribution, your version of Mac OS, Windows, or other operating system) shouldn't be tampered with. That Python installation and its modules are managed by the maintainer of the operating system, and in general it's not a good idea to make changes there unless you are certain of what you are doing. Having a single personal installation of Python, however, is usually not enough, as different projects may have different requirements. For example, the newest version of a package might break the API compatibility and unless we are ready to move the whole project to the new API, we want to keep the version of that package fixed and avoid any update. At the same time another project may require the bleeding edge or even a fork of that package: for example when you have to patch a security issue, or if you need a new feature and can't wait for the usual release cycle that can take weeks.

Ultimately, the idea is that it is cheaper and simpler (at least in 2018) to copy the whole Python installation and to customise it than to try to manage a single installation that satisfies all the requirements. It's the same advantage we have when using virtual machines, but on a smaller scale.

The starting point to become familiar with virtual environments is the [official documentation](https://docs.python.org/3/tutorial/venv.html), but if you experience issues with a specific version of your operating system you will find plenty of resources on Internet that may clarify the matter.

In general, my advice is to have a different virtual environment for each Python project. You may prefer to keep them inside or outside the project's directory. In the latter case the name of the virtual environment shall reflect in some way the associated project. There are packages to manage the virtual environments any simplify your interaction with them, and the most famous one is [virtualenvwrapper](https://virtualenvwrapper.readthedocs.io/en/latest/).

I used to create my virtual environments inside the directory of my Python projects. Since I started using Cookiecutter (see next section) to create new projects, however, I switched to a different setup. Keeping the virtual environment outside the project allows me to install Cookiecutter in the virtualenv, instead of being forced to install it system-wide, which sometimes prevents me from using the latest version.

If you create the virtual environment in the project directory you have to configure your version control and other tools to ignore it. In particular, add it to [`.gitignore`](https://git-scm.com/docs/gitignore) if you use Git and to [`pytest.ini`](https://docs.pytest.org/en/latest/reference.html#confval-norecursedirs) if you use the pytest testing framework (as I do in the rest of this book).

## Python projects with Cookiecutter

Creating a Python project from scratch is not easy. There are many things to configure and I would only suggest manually writing all the files if you strongly need to understand how the Python distribution code works. If you want to focus on your project, instead, it's better to use a template.

[Cookiecutter](https://cookiecutter.readthedocs.io/en/latest/) is a simple but very powerful Python software created by Audrey Roy Greenfeld. It creates directories and files with a template, and can create very complex set-ups, asking you a mere handful of questions. There are already templates for Python (obviously), C, Scala, LaTeX, Go, and other languages, and creating your own template is very simple.

The [official Python template](https://github.com/audreyr/cookiecutter-pypackage) is maintained by the same author of Cookiecutter. Other Python templates with different set-ups or that rely on different tools are available, and some of them are linked in the Cookiecutter README file.

I maintain [a Python project template](https://github.com/lgiordani/cookiecutter-pypackage) that I will use throughout the book. You are not required to use it, actually I encourage you to fork it and change what you don't like as soon as you get comfortable with the structure and the role that the various files have.

These templates work perfectly for open source projects. If you are creating a closed source project you will not need some of the files (like the license or the instructions for programmers who want to collaborate), but you can always delete them once you have applied the template. If you need to do this more than once, you can fork the template and change it to suit your needs.

A small issue you might run into is that Cookiecutter is a Python program, and as such it must be installed in your Python environment. In general it is safe to install such a package in the system-wide Python, as it is not a library and it is not going to change the behaviour of important components in the system, but if you want to be safe and flexible I advise you to follow this procedure

* Create a virtual environment for the project, using one of the methods discussed in the previous section, and activate it
* Install Cookiecutter with `pip install cookiecutter`
* Run Cookiecutter with your template of choice `cookiecutter <template_URL>`, answering the questions
* Install the requirements following the instructions of the template itself `pip install -r <requirements_file>`

Refer to the `README` of the Cookiecutter template to better understand the questions that the program will ask you and remember that if you make a mistake you can always delete the project and run Cookiecutter again.

If you are using my project template the questions you will be asked are

**full_name**: Your full name
**email**: Your contact email
**github_username**: Your GitHub username 
**project_name**: The name of the project
**project_slug**: The slug for the project
**project_short_description**: A description for the project
**pypi_username**: Your PyPI username, if you want to publish the package
**version** [0.1.0]: The current version of the package
**use_pytest** [n]: If you want to use pytest to test the package (in this book always "y")
**use_pypi_deployment_with_travis** [y]: Publish on PyPI when test pass (you usually don't want this feature turned on when you are testing or in the initial stages of the development)
**command_line_interface** This allows to create a command line interface using [click](https://github.com/pallets/click). We are not going to use this feature in the projects presented in the book
**create_author_file**: The file that lists the authors of the package
**open_source_license**: If you are unsure select the MIT license

# Changelog

{icon: quote-right}
B> _What's the last thing you do remember? Hmm?_
B> - Alien (1979)

I will track here changes between releases of the book, following [Semantic Versioning](https://semver.org/). A change in the **major** number means an incompatible change, that is a big rewrite of the book, also known as 2nd edition, 3rd edition, and so on. I don't know if this will ever happen, but the version number comes for free. A change in the **minor** number means that something important was added to the content, like a new section or chapter. A change in the **patch** number signals minor fixes like typos in the text or the code, rewording of sentences, and so on.

**Current version**: 1.0.11

**Version 1.0.11 (2020-02-15)**
* GitHub user [lrfuentesw](https://github.com/lrfuentesw) spotted an error in the memory repository. Price filters with a string value were not working because they were not converted into integers. Thank you!

**Version 1.0.10 (2019-09-23)**
* GitHub user [Ramces Chirino](https://github.com/chirinosky) submitted a mega PR with mant grammatical corrections. Thanks!

**Version 1.0.9 (2019-04-12)**
* GitHub user [plankington](https://github.com/plankington) fixed some typos. Thank you!

**Version 1.0.8 (2019-03-19)**
* GitHub users [Faust Gertz](https://github.com/faustgertz) and [Michael "Irish" O'Neill](https://github.com/IrishPrime) spotted a bug in the code of the `calc` example, chapter 1 of part 1. Thanks!
* GitHub user [Ahmed Ragab](https://github.com/Ragabov) fixed some typos. Thank you so much!

**Version 1.0.7 (2019-03-02)**
* GitHub user [penguindustin](https://github.com/penguindustin) suggested adding `pipenv` in the tools section as it is officially recommended by the Python packaging User Guide. Thanks!
* GitHub user [godiedelrio](https://github.com/godiedelrio) spotted an error in the `rentomatic/rentomatic/repository/postgresrepo.py` file. The code returned the result of the query without converting the single objects into domain entities. This was not spotted by tests as I haven't introduced tests that check for the nature of the returned objects yet.

**Version 1.0.6 (2019-02-06)**

* The tireless [Eric Smith](https://github.com/genericmoniker) fixed typos and grammar in Part 2, Chapter 4. Thank you so much.

**Version 1.0.5 (2019-01-28)**

* [Eric Smith](https://github.com/genericmoniker) and [Faust Gertz](https://github.com/faustgertz) fixed many typos in part 2. Thanks both for your help.

**Version 1.0.4 (2019-01-22)**

* [Grant Moore](https://github.com/grantmoore3d) and [Hans Chen](https://github.com/hanschen) corrected two typos. Thank you!

**Version 1.0.3 (2019-01-11)**

* [Eric Smith](https://github.com/genericmoniker) fixed more typos and corrected some phrasing in Chapter 3 of Part 1. Thanks Eric!

**Version 1.0.2 (2019-01-09)**

* [Max H. Gerlach](https://github.com/maxhgerlach) spotted and fixed more typos. Thanks again Max!

**Version 1.0.1 (2019-01-01)**

* [Max H. Gerlach](https://github.com/maxhgerlach), [Paul Schwendenman](https://github.com/paul-schwendenman), and [Eric Smith](https://github.com/genericmoniker) kindly fixed many typos and grammar mistakes. Thank you very much!

**Version 1.0.0 (2018-12-25)**

* Initial release
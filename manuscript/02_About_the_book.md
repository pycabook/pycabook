# About the book

{blurb, icon: quote-right}
We'll put the band back together, do a few gigs, we get some bread. Bang! Five thousand bucks.

The Blues Brothers, 1980
{/blurb}


In 2015 I was introduced to the clean architecture by a colleague of mine, Roberto Ciatti. I started working with him following a strict Test-Driven Development (TDD) approach and learning or better understanding many things I now consider pillars of my programming knowledge.

Unfortunately the project was cancelled, but the clean architecture concepts stuck with me, so I revisited them for a simple open source project I started working on at the time. Meanwhile I read "Object Oriented Software Engineering: A Use-Case Driven Approach" by Ivar Jacobson[^footnote1].

In 2013 I started writing a personal blog, [The Digital Cat](https://www.thedigitalcatonline.com/), and after having published many Python-related posts I began working on a post to show other programmers the beauty of the clean architecture concepts: "Clean Architectures in Python: a step by step example", published in 2016, which was well received by the Python community. For a couple of years I considered expanding the post, but I couldn't find the time to do it, and in the meanwhile I realised that many things I had written needed to be corrected, clarified, or simply updated. So I thought that a book could be the best way to present the whole picture effectively, and here we are.

In 2020, after having delayed it for a long time, I decided to review the whole book, updating it and clarifying parts that weren't particularly well written. I also decided to remove the part on TDD. While I believe every programmer should understand TDD, the topic of the book is different, so I updated the material and published it on my blog.

This book is the product of many hours spent thinking, experimenting, studying, and making mistakes. I couldn't have written it without the help of many people, some of whose names I don't know, who provided free documentation, free software, free help. Thanks everybody! I also want to specifically say thanks to many readers who came back to me with suggestions, corrections, or simply with appreciation messages. Thanks all!

## Prerequisites and structure of the book

To fully appreciate the book you need to know Python and be familiar with TDD, in particular with unit testing and mocks. Please refer to the series [TDD in Python with pytest](https://www.thedigitalcatonline.com/blog/2020/09/10/tdd-in-python-with-pytest-part-1/) published on my blog if you need to refresh your knowledge about these topics.

After the two introductory parts that you are reading, chapter 1 goes through a **10,000 feet overview** of a system designed with a  clean architecture, while chapter 2 briefly discusses the **components** and the ideas behind this software architecture. Chapter 3 runs through **a concrete example** of clean architecture and chapter 4 expands the example adding a **web application** on top of it. Chapter 5 discusses **error management** and improvements to the Python code developed in the previous chapters. Chapters 6 and 7 show how to plug **different database systems** to the web service created previously, and chapter 8 wraps up the example showing how to run the application with a **production-ready configuration**.

## Typographic conventions

This book uses Python, so the majority of the code samples will be in this language, either `inline` or in a specific code block like this

{caption: "`some/path/file_name.py`"}
``` python
def example():
    print("This is a code block")
```
Note that the path of the file that contains the code is printed just before the source code. Code blocks don't include line numbers, as the part of code that are being discussed are usually repeated in the text. This also makes it possible to copy the code from the PDF directly.

Shell commands are presented with a generic prompt `$`

``` bash
$ command --option1 value1 --option2 value 2
```
which means that you will copy and execute the string starting from `command`.

I will also use two different asides to link the code repository and to mark important principles.

This box provides a link to the commit or the tag that contains the code that was presented

{blurb, class: tip}
**Source code**

<https://github.com/pycabook/rentomatic/tree/master>
{/blurb}


This box highlights a concept explained in detail in the current chapter

{blurb, class: tip}
**Concept**

This recaps an important concept that is explained in the text.
{/blurb}


## Why this book comes for free

The first reason I started writing a technical blog was to share with others my discoveries, and to save them the hassle of going through processes I had already cracked. Moreover, I always enjoy the fact that explaining something forces me to better understand that topic, and writing requires even more study to get things clear in my mind, before attempting to introduce other people to the subject.

Much of what I know comes from personal investigations, but without the work of people who shared their knowledge for free I would not have been able to make much progress. The Free Software Movement didn't start with Internet, and I got a taste of it during the 80s and 90s, but the World Wide Web undeniably gave an impressive boost to the speed and quality of this knowledge sharing.

So this book is a way to say thanks to everybody gave their time to write blog posts, free books, software, and to organise conferences, groups, meetups. This is why I teach people at conferences, this is why I write a technical blog, this is the reason behind this book.

That said, if you want to acknowledge my effort with money, feel free. Anyone who publishes a book or travels to conferences incurs expenses, and any help is welcome. However, the best thing you can do is to become part of this process of shared knowledge; experiment, learn and share what you learn. If you'd like to contribute financially you can purchase the book on [Leanpub](https://leanpub.com/clean-architectures-in-python).

## Submitting issues or patches

This book is not a collaborative effort. It is the product of my work, and it expresses my personal view on some topics, and also follows my way of teaching. Both however can be improved, and they might also be wrong, so I am open to suggestions, and I will gladly receive any report about mistakes or any request for clarifications. Feel free to use the GitHub Issues of the [book repository](https://github.com/pycabook/pycabook/issues) or of the projects presented in the book. I will answer or fix issues as soon as possible, and if needed I will publish a new version of the book with the correction. Thanks!

## About the author

My name is Leonardo Giordani, I was born in 1977, a year that gave to the world Star Wars, bash, Apple II, BSD, Dire Straits, The Silmarillion, among many other things. I'm interested in operating systems and computer languages, photography, fantasy and science fiction, video and board games, guitar playing, and (too) many other things.

I studied and used several programming languages, among them my favourite are the Motorola 68k Assembly, C, and Python. I love mathematics and cryptography. I'm mainly interested in open source software, and I like both the theoretical and practical aspects of computer science.

For 13 years I have been a C/Python programmer and devops for a satellite imagery company, and I am currently one of the lead developers at [WeGotPOP](https://www.wegotpop.com), a UK company based in London and New York that creates innovative software for film productions.

In 2013 I started publishing some technical thoughts on my blog, [The Digital Cat](https://www.thedigitalcatonline.com), and in 2018 I published the first edition of the book you are currently reading.

## Changes in the second edition

New edition, new typos! I'm pretty sure this is the major change I introduced with this edition.

Jokes aside, this second edition contains many changes, but the core example is the same, and while the code changed a little (I use dataclasses and introduced a management script to orchestrate tests) nothing revolutionary happened from that point of view.

So, if you already read the first edition, you might want to have a look at chapters 6, 7, and 8, where I reworked the way I manage integration tests and the production-ready setup of the project. If you haven't read the first edition I hope you will appreciate the effort I made to introduce the clean architecture with a narrated example in chapter 1, before I start discussing the architecture in more detail and show you some code.

The biggest change that readers of the first edition might notice in the content is that I removed the part on TDD and focused only on the clean architecture. What I wrote on TDD has become a series of 5 posts on my blog, that I reference in the book, but this time I preferred to stay faithful to the title and discuss only the subject matter. This probably means that the book is not suitable for complete beginners any more, but since the resources are out there I don't feel too guilty.

I also experimented with different toolchains. The first edition was created directly with [Leanpub's Markua](https://leanpub.com/markua/read) language, which gave me all I needed to start. While working on the second edition, though, I grew progressively unsatisfied because of the lack of features like admonitions and file names for the source snippets, and a general lack of configuration options. I think Leanpub is doing a great job, but Markua didn't provide all the features that I needed. So I tried [Pandoc](https://pandoc.org/), and I immediately hit the wall of Latex, which is obscure black magic to say the least. I spent a great amount of time hacking templates and Python filters to get more or less what I wanted, but I wasn't happy.

Eventually I discovered [AsciiDoc](https://asciidoc.org/) and that looked like the perfect solution. I actually published the first version of the second edition with this toolchain, and I was blown away by AsciiDoc in comparison with Markdown. Unfortunately I had a lot of issues trying to customise the standard template, and not knowing Ruby worsened my experience. After a while I got to a decent version (which I published), but I kept thinking that I wanted more.

So I decided to try to write my own parser and here we go. This version of the book has been written using Mau, which is available at <https://github.com/Project-Mau>, and Pelican (<https://getpelican.com>), which I already successfully use for my blog. I'm in the process of writing a Mau Visitor that converts the source code into Markua, so that I can use Leanpub's tools to produce a PDF.

I hope you will enjoy the effort I put into this new edition!

[^footnote1]: <https://www.amazon.com/Object-Oriented-Software-Engineering-Approach/dp/0201544350>
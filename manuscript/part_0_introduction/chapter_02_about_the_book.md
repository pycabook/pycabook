# About the book

{icon: quote-right}
B> _We'll put the band back together, do a few gigs, we get some bread. Bang! Five thousand bucks._
B> - The Blues Brothers (1980)

## A brief history of this book

In 2015 I was introduced to the clean architecture by Roberto Ciatti. I started working with him following a strict Test-Driven Development (TDD) approach and learning or better understanding many things I consider pillars of my programming knowledge now.

Unfortunately the project was cancelled, but the clean architecture concepts stuck with me, so I revisited them for a simple open source project I started working on at the time [^punch]. Meanwhile I read "Object Oriented Software Engineering: A Use-Case Driven Approach" by Ivar Jacobson[^ivar-jacobson-book].

[^punch]: [https://github.com/lgiordani/punch](https://github.com/lgiordani/punch)
[^ivar-jacobson-book]: [https://www.amazon.com/Object-Oriented-Software-Engineering-Approach/dp/0201544350](https://www.amazon.com/Object-Oriented-Software-Engineering-Approach/dp/0201544350)

In 2013 I started writing a personal blog, [The Digital Cat](http://blog.thedigitalcatonline.com/), and after having published many Python-related posts I began working on a post to show other programmers the beauty of the clean architecture concepts: "Clean Architectures in Python: a step by step example", published in 2016, which was well received by the Python community. For a couple of years I considered expanding the post, but I couldn't find the time to do it, and in the meanwhile I realised that many things I had written needed to be corrected, clarified, or simply updated.

I also saw that other posts of mine could clarify parts of the methodology used in developing a project based on the clean architecture, such as the introduction to TDD. So I thought that a book could be the best way to present the whole picture effectively, and here we are.

This book is the product of many hours' thinking, experimenting, studying, and making mistakes. I couldn't have written it without the help of many people, some of whose names I don't know, who provided free documentation, free software, free help.

Errors: be aware there will be many. I'm not a native English speaker and a friend kindly proofread the opening, less technical chapters, trying to mitigate the worst errors. In the future I may consider having it reviewed by a professional. For now I can only apologise in advance for my mistakes and hope you will nevertheless enjoy the book and be able to use it effectively.

## How this book is structured

This book is divided into two parts.

The first part is about **Test-driven Development (TDD)**, a programming technique that will help you more reliable and easily modifiable software. I will first guide you through a **very simple example** in chapter 1, demonstrating how to use TDD to approach a project, and how to properly create tests from requirements. In chapter 2 I will then discuss **unit testing** from a more theoretical point of view, categorising functions and their tests. Chapter 3 will introduce **mocks**, a powerful tool that helps to test complex scenarios.

The second part introduces **the clean architecture**. The first chapter discusses briefly the **components** and the ideas behind this software structure, while chapter 2 runs through **a concrete example** of clean architecture for a very simple web service. Chapter 3 discusses **error management** and improvements to the Python code developed in the previous chapter. Finally, chapter 4 shows how to plug **different database systems** to the web service created previously.

## Typographic conventions

This book uses Python, so the majority of the code samples will be in this language, either `inline` or in a specific code block

``` python
def example():
    print("This is a code block")
```

Code blocks don't include line numbers, as the part of code that are being discussed are usually repeated in the text. This also makes it possible to copy the code from the PDF directly.

{icon: github}
B> This aside provides the link to the repository tag that contains the code that was presented

{icon: graduation-cap}
B> This is a recap of a rule that was explained and exemplified

## Why this book comes for free

The first reason I started writing a technical blog was to share with others my discoveries, and to save them the hassle of going through processes I had already cracked. Moreover, I always enjoy the fact that explaining something forces me to better understand that topic, and writing requires even more study to get things clear in my mind, before attempting to introduce other people to the subject.

Much of what I know comes from personal investigations, but without the work of people who shared their knowledge for free I would not have been able to make much progress. The Free Software Movement didn't start with Internet, and I got a taste of it during the 80s and 90s, but the World Wide Web undeniably gave an impressive boost to the speed and quality of this knowledge sharing.

So this book is a way to say thanks to everybody gave their time to write blog posts, free books, software, and to organise conferences, groups, meetups. This is why I teach people at conferences, this is why I write a technical blog, this is the reason for this book.

That said, if you want to acknowledge the effort with money, feel free. Anyone who publishes a book or travels to conferences incurs expenses, and any help is welcome. However the best thing you can do is to become part of this process of shared knowledge; experiment, learn and share what you learn.

## Submitting issues or patches

This book is not a collaborative effort. It is the product of my work, and it expresses my personal view on some topics, and also follows my way of teaching. Both can definitely be improved, and they might also be wrong, so I am open to suggestions, and I will gladly receive any report about mistakes or any request for clarifications. Feel free to use the GitHub Issues of the [book repository](https://github.com/pycabook/pycabook/issues) or of the projects presented in the book. I will answer or fix issues as soon as possible, and if needed I will publish a new version of the book with the correction. Thanks!

## About the author

My name is Leonardo Giordani, I was born in 1977 with Star Wars, bash, Apple ][, BSD, Dire Straits, The Silmarillion. I'm interested in operating systems and computer languages, photography, fantasy and science fiction, video and board games, guitar playing, and (too) many other things.

I studied and used several programming languages, from the Z80 and x86 Assembly to Python and Scala. I love mathematics and cryptography. I'm mainly interested in open source software, and I like both the theoretical and practical aspects of computer science.

For 13 years I was a C/Python programmer and devops for a satellite imagery company. and I am currently infrastructure engineer at [WeGotPOP](https://www.wegotpop.com), a UK company based in London and New York that creates innovative software for film productions.

In 2013 I started publishing some technical thoughts on my blog, [The Digital Cat](http://thedigitalcatonline.com).

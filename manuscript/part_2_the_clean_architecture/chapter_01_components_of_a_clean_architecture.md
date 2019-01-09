# Chapter 1 - Components of a clean architecture

{icon: quote-right}
B> _Wait a minute. Wait a minute Doc, uh, are you telling me you built a time machine... out of a DeLorean?_
B> - Back to the Future (1985)

## Layers and data flow

A clean architecture is a layered architecture, which means that the various elements of your system are categorised and have a specific place where to be, according to the category you assigned them. A clean architecture is also a spherical architecture, with inner (lower) layers completely encompassed by outer (higher) ones, and the former ones being oblivious of the existence of the latter ones.

The deeper a layer is in the architecture, the more abstract the content is. The inner layers contain representations of business concepts, while the outer layers contain specific details about the real-life implementation. The communication between elements that live in the same layer is unrestricted, but when you want to communicate with elements that have been assigned to other layers you have to follow one simple rule. This rule is the most important thing in a clean architecture, possibly being the core expression of the clean architecture itself.

_Talk inwards with simple structures, talk outwards through interfaces._

Your elements should talk inwards, that is pass data to more abstract elements, using basic structures provided by the language (thus globally known) or structures known to those elements. Remember that an inner layer doesn't know anything about outer ones, so it cannot understand structures defined there.

You elements should talk outwards using interfaces, that is using only the expected API of a component, without referring to a specific implementation. When an outer layer is created, elements living there will plug themselves into those interfaces and provide a practical implementation.

## Main layers

Let's have a look at the main layers of a clean architecture, keeping in mind that your implementation may require to create new layers or to split some of these into multiple ones.

### Entities

This layer of the clean architecture contains a representation of the domain models, that is everything your project need to interact with and is sufficiently complex to require a specific representation. For example, strings in Python are complex and very powerful objects. They provide many methods out of the box, so in general it is useless to create a domain model for them. If your project is a tool to analyse medieval manuscripts, however, you might need to isolate sentences and at this point maybe you need a specific domain model.

Since we work in Python, this layer will contain classes, with methods that simplify the interaction with them. It is very important, however, to understand that the models in this layer are different from the usual models of frameworks like Django. These models are not connected with a storage system, so they cannot be directly saved or queried using methods of their classes, they don't contain methods to dump themselves to JSON strings, they are not connected with any presentation layer. They are so-called lightweight models.

This is the inmost layer. Entities have a mutual knowledge since they live in the same layer, so the architecture allows them to interact directly. This means that one of your Python classes can use another one directly, instantiating it and calling its methods. Entities don't know anything that lives in outer layers, however. For example, entities don't know details about the external interfaces, and they only work with interfaces.
  
### Use cases

This layer contains the use cases implemented by the system. Use cases are the processes that happen in your application, where you use you domain models to work on real data. Examples can be a user logging in, a search with specific filters being performed, or a bank transaction happening when the user wants to buy the content of the cart.

A use case should be as small a possible. It is very important to isolate small actions in use cases, as this makes the whole system easier to test, understand and maintain.

Use cases know the entities, so they can instantiate them directly and use them. They can also call each other, and it is common to create complex use cases that put together other simpler ones.

### External systems

This part of the architecture is made by external systems that implement the interfaces defined in the previous layer. Examples of these systems can be a specific framework that exposes an HTTP API, or a specific database.

## APIs and shades of grey

The word API is of uttermost importance in a clean architecture. Every layer may be accessed by elements living in inner layers by an API, that is a fixed[^fixed] collection of entry points (methods or objects).

[^fixed]: here "fixed" means "the same among every implementation". An API may obviously change in time.

The separation between layers and the content of each layer are not always fixed and immutable. A well-designed system shall also cope with practical world issues such as performances, for example, or other specific needs. When designing an architecture it is very important to know "what is where and why", and this is even more important when you "bend" the rules. Many issues do not have a black-or-white answer, and many decisions are "shades of grey", that is it is up to you to justify why you put something in a given place.

Keep in mind however, that you should not break the _structure_ of the clean architecture, in particular you shall be very strict about the data flow. If you break the data flow, you are basically invalidating the whole structure. You should try as hard as possible not to introduce solutions that are based on a break in the data flow, but realistically speaking, if this saves money, do it.

If you do it, there should be a giant warning in your code, and in your documentation, explaining why you did it. If you access an outer layer breaking the interface paradigm usually it is because of some performance issues, as the layered structure can add some overhead to the communications between elements. You should clearly tell other programmers that this happened, because if someone wants to replace the external layer with something different they should know that there is a direct access which is implementation specific.

For the sake of example, let's say that a use case is accessing the storage layer through an interface, but this turns out to be too slow. You decide then to access directly the API of the specific database you are using, but this breaks the data flow, as now an internal layer (use cases) is accessing an outer one (external interfaces). If someone in the future wants to replace the specific database you are using with a different one, they have to be aware of this, as the new database probably won't provide the same API entry point with the same data.

If you end up breaking the data flow consistently maybe you should consider removing one layer of abstraction, merging the two layers that you are linking.


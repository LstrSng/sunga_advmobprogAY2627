# John Lester M. Sunga
## INF 231 MWA
## CTADMOBL Advance Mobile Programming

A Flutter project that focuses on advance topics. Covering the Mobile to Web transactions.

## Lab Activity Instance
## Lab Activity 1: discussion
setState manages local, temporary state within a single widget by rebuilding its entire UI, whereas Provider manages shared, app-wide state by separating business logic from the UI, allowing any widget across the tree to access data directly and rebuilding only the specific components that depend on it.

## Lab Activity 2: discussion

ProductService calls the API, Product converts the raw JSON into a Dart object, and the screen asks the service for that data and displays it — it never calls http directly. This is the Repository/Service pattern: a service layer sits between the UI and the API so only ProductService needs to change if the API changes.

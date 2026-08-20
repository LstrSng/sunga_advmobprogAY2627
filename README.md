# John Lester M. Sunga
## INF 231 MWA
## CTADMOBL Advance Mobile Programming

A Flutter project that focuses on advance topics. Covering the Mobile to Web transactions.

## Lab Activity Instance

## Lab Activity 2: discussion

ProductService calls the API, Product converts the raw JSON into a Dart object, and the screen asks the service for that data and displays it — it never calls http directly. This is the Repository/Service pattern: a service layer sits between the UI and the API so only ProductService needs to change if the API changes.

## Lab Activity 3: discussion

Cart/CartProduct convert carts JSON into Dart objects, CartService is the only class that calls http for cart data, and CartScreen just asks it for data — same Repository/Service pattern as Lab 2, applied to a second endpoint. Since CartProduct only carries a summary (no description, images, reviews), tapping a cart item doesn't open its own cart-detail screen: CartScreen calls ProductService.getProductById(item.id) for the full Product, then pushes the existing DetailScreen — the updated pattern is one screen reused across two entry points instead of duplicated per feature. getProductById (GET /products/{id}) is this activity's "get by id" — the Cart API has its own GET /carts/{id} for a single cart, but since there's no login yet, CartService.getCartsByUser(userId) uses GET /carts/user/{userId} instead, scoping to a fixed demo user rather than a specific cart id.
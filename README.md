# John Lester M. Sunga
## INF 231 MWA
## CTADMOBL Advance Mobile Programming

A Flutter project that focuses on advance topics. Covering the Mobile to Web transactions.

## Lab Activity Instance

## Lab Activity 1: discussion

setState manages local, temporary state within a single widget by rebuilding its entire UI, whereas Provider manages shared, app-wide state by separating business logic from the UI, allowing any widget across the tree to access data directly and rebuilding only the specific components that depend on it.

## Lab Activity 2: discussion

ProductService calls the API, Product converts the raw JSON into a Dart object, and the screen asks the service for that data and displays it — it never calls http directly. This is the Repository/Service pattern: a service layer sits between the UI and the API so only ProductService needs to change if the API changes.

## Lab Activity 3: discussion

Cart/CartProduct convert carts JSON into Dart objects, CartService is the only class that calls http for cart data, and CartScreen just asks it for data — same Repository/Service pattern as Lab 2, applied to a second endpoint. Since CartProduct only carries a summary (no description, images, reviews), tapping a cart item doesn't open its own cart-detail screen: CartScreen calls ProductService.getProductById(item.id) for the full Product, then pushes the existing DetailScreen — the updated pattern is one screen reused across two entry points instead of duplicated per feature. getProductById (GET /products/{id}) is this activity's "get by id" — the Cart API has its own GET /carts/{id} for a single cart, but since there's no login yet, CartService.getCartsByUser(userId) uses GET /carts/user/{userId} instead, scoping to a fixed demo user rather than a specific cart id.

## Lab Activity 4 : discussion

User is the model, UserService is the only class that talks to the API/SharedPreferences for auth data, and ProfileScreen just asks UserService().getUser() for the signed-in user and displays it — same Repository/Service pattern as Labs 2-3, now applied to /auth/login. The updated pattern adds a persistence layer: UserService saves the login response to SharedPreferences and later reads it back, so the service acts as a local cache in front of the API instead of hitting it on every screen. This saved user id is also what scopes the cart: CartScreen no longer calls CartService.getCartsByUser with a hardcoded demo id like in Lab 3 — it first reads UserService().getUser().id, then passes that real id into getCartsByUser, so the cart shown is always the signed-in user's own cart.

## Lab Activity 5 : discussion

For DummyJSON, the user signs in with a username and password, UserService sends it to /auth/login, and the returned user details and token are saved in SharedPreferences, while sign up is only simulated through /users/add so the new user is not really saved. For Firebase, the user signs up on the signup screen with their details and a validated password, UserService creates a real account using the Firebase Auth SDK, and then the user signs in with their email and password, which Firebase checks on its servers. The sign-in screen uses Firebase if the input has an @ and DummyJSON if it does not, and the profile allows updating the username, changing the password, deleting the account, and logging out back to the login screen. The main idea of UserService is to keep all the sign-in and account functions in one place, so the screens only call UserService and do not need to know if the user came from DummyJSON or Firebase, and only UserService needs to change if the backend changes. The benefits of Firebase in this app are real accounts saved in the cloud, secure password handling, staying logged in even after closing the app, automatic token refresh, security rules based on the user's ID, and built-in functions for changing the username, changing the password, and deleting the account without building our own backend.

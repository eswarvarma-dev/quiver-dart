quiver-dart
===========

A set of utility libraries for Dart

## iterables.dart

Functions for transforming Iterables in different ways, similar to Python's
itertools.

These include `count`, `cycle`, `enumerate`, `range`, `zip`, `min`, `max`, and
`extent`.

## async.dart

Utilities for working with Futures, Streams and async computations.

`FutureGroup`: A collection of Futures that signals when all it's child futures
have completed. Allows adding new Futures as long as it hasn't completed yet.
Useful when async tasks can spwn new async tasks and you need to wait for all of
them to complete.

`doWhileAsync` and `reduceAsync`: Perform async computations on Iterables.

## io.dart

`visitDirectory`: A recursive directory lister that conditionally recurses into
sub-directories based on the result of a handler function.
# Dio cookie handler/manager. ![workflow](https://github.com/hurelhuyag/dio_cookie_cached_handler/actions/workflows/ci.yaml/badge.svg)

Manager Dio Cookies in non web environments.

## Features

- Stores cookies in single file when changed
- Keep cookies in memory to provide when needed
- Supports Expires, Max-Age attributes.
- No Other attribute support.
- Cookies loaded from file when needed. No Async/Await setup needed

## Getting started

pubspec.yaml
```
dependencies:
  dio_cookie_caching_handler:
    git: git@github.com:hurelhuyag/dio_cookie_cached_handler.git
```

Run this command
```bash
flutter pub get
```

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

Setup:
```dart
import 'package:dio/dio.dart';
import 'package:dio_cookie_caching_handler/dio_cookie_caching_handler.dart';
import 'package:flutter/foundation.dart';

final dio = Dio();
if (!kIsWeb) {
  dio.interceptors.add(cookieCachedHandler()); 
}
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.

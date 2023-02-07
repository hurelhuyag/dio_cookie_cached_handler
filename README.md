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

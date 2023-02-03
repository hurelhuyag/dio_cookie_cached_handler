import 'dart:io';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import 'cookie.dart';
import 'package:flutter/foundation.dart';

class CookieStorage {

  DateFormat cookieDateFormat = DateFormat("EEE, dd MMM yyyy HH':'mm':'ss 'GMT'");
  File? _file;
  final Set<Cookie> _cookies = {};
  final Future<String> storePath;
  
  CookieStorage(this.storePath);

  Future<File> _ensureOpen() async {
    if (_file == null) {
      await _init();
    }
    return _file!;
  }

  Future<void> clear() async {
    _cookies.clear();
    final file = _file;
    if (file != null && file.existsSync()) {
      file.deleteSync();
    }
  }

  Future<void> _init() async {
    final file = File(await storePath);
    debugPrint("restoring from: $file");
    final exists = await file.exists();
    if (exists) {
      final lines = await file.readAsLines();
      final now = DateTime.now();
      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty) {
          continue;
        }
        debugPrint("restoring cookie $line");
        final i = line.indexOf('=');
        final j = line.indexOf(';', i);
        final key = line.substring(0, i);
        final value = line.substring(i+1, j);
        final expireStr = line.substring(j +1);
        final expire = DateTime.parse(expireStr);
        if (now.isAfter(expire)) {
          continue;
        }
        _cookies.add(Cookie(name: key, value: value, expires: expire));
      }
    } else {
      await file.create();
    }
    _file = file;
  }

  Future<void> storeAll() async {
    final file = await _ensureOpen();
    final sink = file.openWrite(mode: FileMode.write);
    debugPrint("storing into $file");
    try {
      final now = DateTime.now();
      final remove = <Cookie>[];
      for (final cookie in _cookies) {
        if (now.isBefore(cookie.expires)) {
          debugPrint("storing cookie: ${cookie.name}=${cookie.value};${cookie.expires.toIso8601String()}");
          sink
            ..write(cookie.name)
            ..write("=")
            ..write(cookie.value)
            ..write(";")
            ..write(cookie.expires.toIso8601String())
            ..write("\n");
        } else {
          remove.add(cookie);
        }
      }
      debugPrint("removing expired cookies: $remove");
      _cookies.removeAll(remove);
    } finally {
      await sink.flush();
      await sink.close();
    }
  }

  Future<void> storeFromRes(Response<dynamic> res) async {
    final setCookies = res.headers["Set-Cookie"];
    if (setCookies != null) {
      debugPrint("Set-Cookie headers $setCookies");
      final now = DateTime.now();
      for (final setCookie in setCookies) {
        final i = setCookie.indexOf('=');
        final j = setCookie.indexOf(';', i);
        final key = setCookie.substring(0, i);
        final value = j == -1 ? setCookie.substring(i+1) : setCookie.substring(i+1, j);
        DateTime? expires;
        if (j != -1) {
          final expiresStart = setCookie.indexOf("Expires=");
          if (expiresStart != -1) {
            final expiresValueStart = expiresStart + 8;
            final expiresEnd = setCookie.indexOf(';', expiresValueStart);
            final expiresStr = expiresEnd == -1
                ? setCookie.substring(expiresValueStart)
                : setCookie.substring(expiresValueStart, expiresEnd);
            expires = cookieDateFormat.parse(expiresStr);

            if (expires.isBefore(now)) {
              _cookies.remove(key);
              continue;
            }
          } else {
            final maxAgeStart = setCookie.indexOf("Max-Age=");
            if (maxAgeStart != -1) {
              final maxAgeValueStart = maxAgeStart + 8;
              final maxAgeValueEnd = setCookie.indexOf(';', maxAgeValueStart);
              final maxAgeStr = maxAgeValueEnd == -1
                  ? setCookie.substring(maxAgeValueStart)
                  : setCookie.substring(maxAgeValueStart, maxAgeValueEnd);
              final maxAge = int.parse(maxAgeStr);
              if (maxAge == 0) {
                _cookies.remove(key);
                continue;
              }
              expires = now.add(Duration(seconds: maxAge));
            }
          }
        }
        expires ??= now.add(const Duration(days: 400));
        _cookies.removeWhere((element) => element.name == key);
        _cookies.add(Cookie(name: key, value: value, expires: expires));
      }
      await storeAll();
    }
  }

  Future<void> loadToReq(RequestOptions options) async {
    await _ensureOpen();
    if (_cookies.isNotEmpty) {
      final result = StringBuffer();
      final now = DateTime.now();
      final remove = <Cookie>[];
      for (final cookie in _cookies) {
        if (now.isAfter(cookie.expires)) {
          remove.add(cookie);
          continue;
        }
        if (result.isNotEmpty) {
          result.write("; ");
        }
        result.write("${cookie.name}=${cookie.value}");
      }
      _cookies.removeAll(remove);
      options.headers["cookie"] = result.toString();
    }
  }
}

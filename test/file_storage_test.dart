import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_cookie_caching_handler/cookie_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cookiePath = "/tmp/.dio.cookie_storage.test";

  tearDown(() {
    debugPrint("cleaning temp file");
    final file = File(cookiePath);
    if (file.existsSync()) {
      file.deleteSync();
    }
  });

  test('restore from file', () async {
    final expire = DateTime.now().add(const Duration(days: 1));
    final file = File(cookiePath);
    await file.writeAsString("""
ZNTS=123456789;${expire.toIso8601String()}
ZNTR=r123;${expire.toIso8601String()}

    """);

    final cs = CookieStorage(Future.value(cookiePath));
    final ro = RequestOptions(path: "/api/v1", headers: {});
    await cs.loadToReq(ro);
    expect(ro.headers.length, 2);
    expect(ro.headers["cookie"], "ZNTS=123456789; ZNTR=r123");
  });

  test('restore from file with expired cookie', () async {
    final expire1 = DateTime.now().add(const Duration(days: 1));
    final expire2 = DateTime.now().subtract(const Duration(days: 1));
    final file = File(cookiePath);
    await file.writeAsString("""
ZNTS=123456789;${expire1.toIso8601String()}
ZNTR=r123;${expire2.toIso8601String()}

    """);

    final cs = CookieStorage(Future.value(cookiePath));
    final ro = RequestOptions(path: "/api/v1", headers: {});
    await cs.loadToReq(ro);
    expect(ro.headers.length, 2);
    expect(ro.headers["cookie"], "ZNTS=123456789");
  });

  test('storing to file', () async {
    final cs = CookieStorage(Future.value(cookiePath));
    await cs.storeFromRes(Response(
        requestOptions: RequestOptions(path: "/api/v1"),
        headers: Headers()
          ..add("set-cookie", "ZNTS=v1")
          ..add("set-cookie", "ZNTR=r123")));

    final file = File(cookiePath);
    expect(file.existsSync(), true);

    final lines = await file.readAsString();
    debugPrint(lines);
    expect(lines.contains("ZNTS=v1;"), true);
    expect(lines.contains("ZNTR=r123;"), true);
  });

  test('storing to file with expired cookie', () async {
    final cs = CookieStorage(Future.value(cookiePath));
    await cs.storeFromRes(Response(
        requestOptions: RequestOptions(path: "/api/v1"),
        headers: Headers()
          ..add("set-cookie", "ZNTS=v1")
          ..add("set-cookie", "ZNTR=r123; Max-Age=0")));

    final file = File(cookiePath);
    expect(file.existsSync(), true);

    final lines = await file.readAsString();
    debugPrint(lines);
    expect(lines.contains("ZNTS=v1;"), true);
    expect(lines.contains("ZNTR=r123;"), false);
  });
}

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_cookie_caching_handler/cookie_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final cookieDateFormat = DateFormat("EEE, dd MMM yyyy HH':'mm':'ss 'GMT'");
  const cookiePath = "/tmp/.dio.cookie_storage.test";

  late CookieStorage cs;
  setUp(() async {
    debugPrint("initializing cookie storage");
    cs = CookieStorage(Future.value(cookiePath));
  });
  tearDown(() async {
    debugPrint("cleaning cookie storage");
    await cs.clear();
  });

  test('make sure cookie storage is empty', () {
    final ro = RequestOptions(path: "/api/v1", headers: {});
    cs.loadToReq(ro);
    expect(ro.headers.length, 1);
    expect(ro.headers["cookie"], null);
  });

  test('simple set-cookie', () async {
    await cs.storeFromRes(Response(
        requestOptions: RequestOptions(path: "/api/v1"), headers: Headers()..add("set-cookie", "ZNTS=1234567890")));

    final ro = RequestOptions(path: "/api/v1", headers: {});
    await cs.loadToReq(ro);
    expect(ro.headers.length, 2);
    expect(ro.headers["cookie"], "ZNTS=1234567890");
  });

  test('simple set-cookie with valueless attribute', () async {
    await cs.storeFromRes(Response(
        requestOptions: RequestOptions(path: "/api/v1"),
        headers: Headers()..add("set-cookie", "ZNTS=1234567890; HttpOnly;")));

    final ro = RequestOptions(path: "/api/v1", headers: {});
    await cs.loadToReq(ro);
    expect(ro.headers.length, 2);
    expect(ro.headers["cookie"], "ZNTS=1234567890");
  });

  test('set-cookie with expires', () async {
    await cs.storeFromRes(Response(
        requestOptions: RequestOptions(path: "/api/v1"),
        headers: Headers()
          ..add("set-cookie",
              "ZNTS=1234567890; Expires=${cookieDateFormat.format(DateTime.now().add(const Duration(days: 1)))}")));

    final ro = RequestOptions(path: "/api/v1", headers: {});
    await cs.loadToReq(ro);
    expect(ro.headers.length, 2);
    expect(ro.headers["cookie"], "ZNTS=1234567890");
  });

  test('set-cookie with expired expires', () async {
    await cs.storeFromRes(Response(
        requestOptions: RequestOptions(path: "/api/v1"),
        headers: Headers()
          ..add("set-cookie",
              "ZNTS=1234567890; Expires=${cookieDateFormat.format(DateTime.now().subtract(const Duration(days: 1)))}")));

    final ro = RequestOptions(path: "/api/v1", headers: {});
    await cs.loadToReq(ro);
    expect(ro.headers.length, 1);
    expect(ro.headers["cookie"], null);
  });

  test('set-cookie with max-age', () async {
    await cs.storeFromRes(Response(
        requestOptions: RequestOptions(path: "/api/v1"),
        headers: Headers()..add("set-cookie", "ZNTS=1234567890; Max-Age=3600")));

    final ro = RequestOptions(path: "/api/v1", headers: {});
    await cs.loadToReq(ro);
    expect(ro.headers.length, 2);
    expect(ro.headers["cookie"], "ZNTS=1234567890");
  });

  test('set-cookie with zero max-age', () async {
    await cs.storeFromRes(Response(
        requestOptions: RequestOptions(path: "/api/v1"),
        headers: Headers()..add("set-cookie", "ZNTS=1234567890; Max-Age=0")));

    final ro = RequestOptions(path: "/api/v1", headers: {});
    await cs.loadToReq(ro);
    expect(ro.headers.length, 1);
    expect(ro.headers["cookie"], null);
  });

  test('set-cookie with multiple cookies', () async {
    await cs.storeFromRes(Response(
        requestOptions: RequestOptions(path: "/api/v1"),
        headers: Headers()
          ..add("set-cookie", "ZNTS=1234567890; HttpOnly; Secure")
          ..add("set-cookie",
              "ZNTR=zntr12345678; Expires=${cookieDateFormat.format(DateTime.now().add(const Duration(days: 1)))}")));

    final ro = RequestOptions(path: "/api/v1", headers: {});
    await cs.loadToReq(ro);
    expect(ro.headers.length, 2);
    expect(ro.headers["cookie"], "ZNTS=1234567890; ZNTR=zntr12345678");
  });

  test('rewrite same cookie', () async {
    final file = File(cookiePath);
    expect(!file.existsSync() || file.lengthSync() == 0, true);

    // initial setup
    await cs.storeFromRes(
        Response(requestOptions: RequestOptions(path: "/api/v1"), headers: Headers()..add("set-cookie", "ZNTS=v1")));

    var ro = RequestOptions(path: "/api/v1", headers: {});
    await cs.loadToReq(ro);
    expect(ro.headers.length, 2);
    expect(ro.headers["cookie"], "ZNTS=v1");

    var fileData = File(cookiePath).readAsLinesSync();
    expect(fileData.length, 1);
    expect(fileData[0].contains("ZNTS=v1"), true);

    // rewrite cookie
    await cs.storeFromRes(
        Response(requestOptions: RequestOptions(path: "/api/v1"), headers: Headers()..add("set-cookie", "ZNTS=v2")));

    ro = RequestOptions(path: "/api/v1", headers: {});
    await cs.loadToReq(ro);
    expect(ro.headers.length, 2);
    expect(ro.headers["cookie"], "ZNTS=v2");

    fileData = File(cookiePath).readAsLinesSync();
    expect(fileData.length, 1);
    expect(fileData[0].contains("ZNTS=v2"), true);
  });
}

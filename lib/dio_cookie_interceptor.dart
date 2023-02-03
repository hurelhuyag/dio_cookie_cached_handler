import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'cookie_storage.dart';

QueuedInterceptorsWrapper cookieCachedHandler() {
  final storage = CookieStorage(getApplicationSupportDirectory().then((value) => "${value.path}/.dio.cookies"));
  return QueuedInterceptorsWrapper(
    onRequest: (options, handler) {
      storage.loadToReq(options);
      handler.next(options);
    },
    onResponse: (res, handler) {
      storage.storeFromRes(res);
      handler.next(res);
    },
    onError: (e, handler) {
      final res = e.response;
      if (res != null) {
        storage.storeFromRes(res);
      }
      handler.next(e);
    },
  );
}

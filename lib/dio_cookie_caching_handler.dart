library dio_cookie_caching_handler;

import 'package:dio_cookie_caching_handler/cookie_storage.dart';

export 'dio_cookie_interceptor.dart';

void enableCookieStorageLogging(bool enabled) {
  cookieStorageLoggingEnabled = enabled;
}

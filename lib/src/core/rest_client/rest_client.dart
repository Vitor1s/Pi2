import 'dart:io';
import 'package:pi2/src/core/rest_client/interceptors/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

final class RestClient extends DioForNative {
  RestClient()
    : super(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 100),
          baseUrl: 'http://192.168.1.46:8080',
        ),
      ) {
    interceptors.addAll([AuthInterceptor(), PrettyDioLogger()]);

    // Usando a API atual em vez da obsoleta 'onHttpClientCreate'
    if (httpClientAdapter is IOHttpClientAdapter) {
      (httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }
  }

  RestClient get auth => this..options.extra['DIO_AUTH_KEY'] = true;
  RestClient get unAuth => this..options.extra['DIO_AUTH_KEY'] = false;
}

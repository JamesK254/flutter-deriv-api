import 'dart:async';

import 'package:flutter_deriv_api/api/authorize_receive.dart';
import 'package:flutter_deriv_api/api/authorize_send.dart';
import 'package:flutter_deriv_api/api/request.dart';
import 'package:flutter_deriv_api/api/response.dart';
import 'package:flutter_deriv_api/connection/connection_websocket.dart';
import 'package:flutter_deriv_api/state/connection/connection_bloc.dart';

/// A layer of abstraction over [BinaryAPI] that works with connection states
/// to handle [Request] and [Response] based on it.
class DerivApi {
  /// Singleton instance of [DerivApi]
  factory DerivApi() => _instance;

  /// Initializes
  DerivApi._() {
    _connectionBloc = ConnectionBloc()
      ..listen((ConnectionState connectionState) {
        if (connectionState is Connected) {
          _connected = true;
          // handle requests in the list
        } else if (connectionState is ConnectionError ||
            connectionState is InitialConnectionState) {
          _connected = false;
          // Propagate error instead of objects
        }
      });

    _binaryAPI = BinaryAPI();
  }

  ///
  Future<bool> init({
    String endpoint = 'www.binaryqa10.com',
    String language = 'en',
    String brand = 'deriv',
    String appId = '1014',
  }) async {
    try {
      await _binaryAPI.run(
        endpoint: endpoint,
        language: language,
        brand: brand,
        appId: appId,
      );
    } on Exception {
      return false;
    }
    return true;
  }

  /// Authorizes and returns [AuthorizeResponse]
  /// todo: Will return and [Account] instance later on.
  Future<AuthorizeResponse> authorize(String token) async {
    final AuthorizeResponse response =
        await _binaryAPI.call(AuthorizeRequest(authorize: token));
    return response;
  }

  static final DerivApi _instance = DerivApi._();

  bool _connected = false;

  ConnectionBloc _connectionBloc;

  BinaryAPI _binaryAPI;

  /// List of requests that came from different part of the APP
  final List<Request> requests = <Request>[];

  ///
  Stream<Response> subscribe(Request request) => _binaryAPI.subscribe(request);

  ///
  Future<Response> call(Request request) => _binaryAPI.call(request);
}

///
abstract class RequestElement<T> {
  ///
  RequestElement(this.request);

  ///
  final Request request;
}

///
class CallRequest<T> extends RequestElement<T> {
  ///
  CallRequest(Request request) : super(request);

  Completer<T> _completer;
}

///
class SubscribeRequest<T> extends RequestElement<T> {
  ///
  SubscribeRequest(Request request) : super(request);

  StreamController<T> _streamController;
}

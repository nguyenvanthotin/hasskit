import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hasskit/helper/GeneralData.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'Logger.dart';

///
/// Application-level global variable to access the WebSockets
///
WebSocket webSocket = WebSocket();

///
/// Put your WebSockets server IP address and port number
///
//const String _SERVER_ADDRESS = "ws://192.168.1.45:34263";
///
///https://www.didierboelens.com/2018/06/web-sockets---build-a-real-time-game/
///

class WebSocket {
  static final WebSocket _sockets = new WebSocket._internal();

  factory WebSocket() {
    return _sockets;
  }

  WebSocket._internal();

  ///
  /// The WebSocket "open" channel
  ///
  IOWebSocketChannel _channel;

  ///
  /// Is the connection established?
  ///
  bool connected = false;

  ///
  /// Listeners
  /// List of methods to be called when a new message
  /// comes in.
  ///
  ObserverList<Function> _listeners = new ObserverList<Function>();

  /// ----------------------------------------------------------
  /// Initialization the WebSockets connection with the server
  /// ----------------------------------------------------------
  initCommunication() async {
    if (gd.loginDataCurrent == null || gd.loginDataCurrent.getUrl.length < 5) {
      return;
    }
    log.d(
        'initCommunication socketUrl ${gd.socketUrl} autoConnect ${gd.autoConnect} connectionStatus ${gd.connectionStatus}');

    ///
    /// Just in case, close any previous communication
    ///
    reset();

    ///
    /// Open a new WebSocket communication
    ///
    try {
      gd.currentUrl = gd.loginDataCurrent.url;
      _channel = new IOWebSocketChannel.connect(gd.socketUrl,
          pingInterval: Duration(seconds: 15));

//      providerData.connectionError = '';
//      providerData.connectionStatus = 'Connecting...';
//      providerData.serverConnected = false;

      ///
      /// Start listening to new notifications / messages
      ///
      _channel.stream.listen(_onData,
          onDone: _onDone, onError: _onError, cancelOnError: false);
    } catch (e) {
      ///
      /// General error handling
      log.e('initCommunication catch $e');
      gd.connectionStatus = 'Error:\n' + e.toString();

      connected = false;
      _channel.sink.close(status.abnormalClosure);

      ///
    }
  }

  /// ----------------------------------------------------------
  /// Closes the WebSocket communication
  /// ----------------------------------------------------------
  reset() {
    if (_channel != null) {
      if (_channel.sink != null) {
        _channel.sink.close();
        connected = false;
        gd.connectionStatus = "reset";
        gd.socketId = 0;
        gd.subscribeEventsId = 0;
        gd.longTokenId = 0;
        gd.getStatesId = 0;
        gd.cameraInfosActive.clear();
      }
    }
  }

  /// ---------------------------------------------------------
  /// Sends a message to the server
  /// ---------------------------------------------------------
  send(String message) {
    log.w("send BEFORE $message");
//    log.d("gd.firebaseCurrentUser==null ${gd.firebaseCurrentUser == null}");
    if (_channel != null) {
      if (_channel.sink != null && connected) {
        var decode = json.decode(message);
        int id = decode['id'];
        String type = decode['type'];

        if (type == 'subscribe_events') {
          if (gd.subscribeEventsId != 0) {
            log.d('??? subscribe_events We do not sub twice');
            return;
          }
          gd.subscribeEventsId = id;
        }
        if (type == 'auth/long_lived_access_token') {
          gd.longTokenId = id;
        }
        if (type == 'get_states') {
          gd.getStatesId = id;
        }

//        log.w("send AFTER $message");
        _channel.sink.add(message);
//        log.d('WebSocket send: id $id type $type $message');
        gd.socketIdIncrement();
      }
    }
  }

  /// ---------------------------------------------------------
  /// Adds a callback to be invoked in case of incoming
  /// notification
  /// ---------------------------------------------------------
  addListener(Function callback) {
    _listeners.add(callback);
  }

  removeListener(Function callback) {
    _listeners.remove(callback);
  }

  /// ----------------------------------------------------------
  /// Callback which is invoked each time that we are receiving
  /// a message from the server
  /// ----------------------------------------------------------
  _onData(message) {
//    log.d("_onData $message");
    connected = true;
    gd.connectionStatus = "Connected";
    gd.connectionOnDataTime = DateTime.now();

    var decode = json.decode(message);

    var type = decode['type'];

    var outMsg;
    switch (type) {
      case 'auth_required':
        {
          if (gd.loginDataCurrent.longToken == null ||
              gd.loginDataCurrent.accessToken == null) {
            if (gd.loginDataList[0] != null) {
              gd.loginDataCurrent = gd.loginDataList[0];
            } else {
              gd.connectionStatus =
                  "Error getting token, please delete old connection data";
              return;
            }
          }

          if (gd.loginDataCurrent.longToken.length > 100) {
            outMsg = {
              "type": "auth",
              "access_token": "${gd.loginDataCurrent.longToken}"
            };
            gd.connectionStatus = "Sending longToken";
            log.e("1. auth longToken");
          } else {
            outMsg = {
              "type": "auth",
              "access_token": "${gd.loginDataCurrent.accessToken}"
            };
            gd.connectionStatus = "Sending accessToken";
            log.e("2. auth accessToken");
          }
          send(json.encode(outMsg));
        }
        break;
      case 'auth_ok':
        {
          if (gd.loginDataCurrent.longToken.length < 100) {
            outMsg = {
              "id": gd.socketId,
              "type": "auth/long_lived_access_token",
              "client_name":
                  "hasskit_${DateTime.now().toUtc().millisecondsSinceEpoch}",
//              "client_name": "${gd.loginDataCurrent.url}",
              "lifespan": 365
            };
            log.e("3. auth/long_lived_access_token");
            gd.connectionStatus = "Sending auth/long_lived_access_token";
          } else {
            outMsg = {
              "id": gd.socketId,
              "type": "subscribe_events",
              "event_type": "state_changed"
            };
            log.e("4. subscribe_events");
            gd.connectionStatus = "Sending subscribe_events";
          }

          gd.loginDataCurrent.lastAccess =
              DateTime.now().millisecondsSinceEpoch;
          var loginDataCurrentInList = gd.loginDataList.firstWhere(
              (e) => e.url == gd.loginDataCurrent.getUrl,
              orElse: () => null);
          if (loginDataCurrentInList == null) {
            log.e("loginDataCurrentInList==null ${gd.loginDataCurrent.getUrl}");
          } else {
            loginDataCurrentInList.lastAccess =
                DateTime.now().millisecondsSinceEpoch;
            gd.loginDataListSortAndSave("auth_ok");
          }

          log.e("5. outMsg $outMsg");
          send(json.encode(outMsg));
        }
        break;
      case 'auth/long_lived_access_token':
        {
          outMsg = {
            "id": gd.socketId,
            "type": "subscribe_events",
            "event_type": "state_changed"
          };
          log.e('6. auth/long_lived_access_token');
          send(json.encode(outMsg));
          gd.connectionStatus = "Sending subscribe_events";
        }
        break;
      case 'result':
        {
          var success = decode['success'];
          if (!success) {
            log.e("!success $message");
            break;
          }

          var id = decode['id'];

          //Processing long_lived_access_token
          if (id == gd.longTokenId) {
            log.w('id == gd.longTokenId');
            String longToken = decode['result'];
            gd.loginDataCurrent.longToken = longToken;
            gd.loginDataList[0].longToken = longToken;
            gd.loginDataListSortAndSave("result");
            log.w("Got the longToken, set and save it $longToken}");
            outMsg = {
              "id": gd.socketId,
              "type": "subscribe_events",
              "event_type": "state_changed"
            };
            log.e('7. auth/long_lived_access_token');
            send(json.encode(outMsg));
          } else if (id == gd.subscribeEventsId) {
            log.e('8. id == gd.subscribeEventsId');
            gd.httpApiStates();
//            use http
//            outMsg = {"id": gd.socketId, "type": "get_states"};
//            send(json.encode(outMsg));
          }
//          use http
//          else if (id == gd.getStatesId) {
//            log.e('9 id == gd.getStatesId');
//            gd.socketGetStates(decode['result']);
//          }
          else if (id == gd.cameraStreamId) {
            log.e('10 id == gd.cameraStreamId');
            gd.cameraStreamUrl = gd.currentUrl + decode['result']["url"];
            log.e(
                "11 cameraStreamId ${gd.cameraStreamId} cameraStreamUrl ${gd.cameraStreamUrl}");
          } else {
//            log.w('result==null $decode');
          }
        }
        break;
      case 'auth_invalid':
        {
          gd.connectionStatus = 'auth_invalid';
        }
        break;
      case 'event':
        {
          gd.connectionStatus = 'Connected';
          gd.socketSubscribeEvents(decode);
        }
        break;
      default:
        {
          log.d('type default $decode');
        }
    }
  }

  void _onDone() {
    gd.connectionStatus = 'Disconnected';
    connected = false;
    log.d('_onDone');
  }

  _onError(error, StackTrace stackTrace) {
    gd.connectionStatus = 'On Error\n' + error.toString();
    connected = false;
    log.d('_onError error: $error stackTrace: $stackTrace');
  }
}

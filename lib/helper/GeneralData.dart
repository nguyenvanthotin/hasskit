import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:core';
import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hasskit/helper/ThemeInfo.dart';
import 'package:hasskit/helper/WebSocket.dart';
import 'package:hasskit/model/BaseSetting.dart';
import 'package:hasskit/model/CameraInfo.dart';
import 'package:hasskit/model/Entity.dart';
import 'package:hasskit/model/EntityOverride.dart';
import 'package:hasskit/model/LoginData.dart';
import 'package:hasskit/model/Room.dart';
import 'package:hasskit/model/Sensor.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:validators/validators.dart';

import 'Logger.dart';
import 'MaterialDesignIcons.dart';

GeneralData gd = GeneralData();
Random random = Random();

enum ViewMode {
  normal,
  edit,
  sort,
}

class GeneralData with ChangeNotifier {
  void saveBool(String key, bool content) async {
    var _preferences = await SharedPreferences.getInstance();
    _preferences.setBool(key, content);
    log.d('saveBool: key $key content $content');
  }

  Future<bool> getBool(String key) async {
    var _preferences = await SharedPreferences.getInstance();
    var value = _preferences.getBool(key) ?? false;
    return value;
  }

  void saveString(String key, String content) async {
    var _preferences = await SharedPreferences.getInstance();
    _preferences.setString(key, content);
    log.d('saveString: key $key content $content');
  }

  Future<String> getString(String key) async {
    var _preferences = await SharedPreferences.getInstance();
    var value = _preferences.getString(key) ?? '';
    return value;
  }

  double _mediaQueryWidth = 411.42857142857144;

  double get mediaQueryWidth => _mediaQueryWidth;

  set mediaQueryWidth(double val) {
//    log.d('mediaQueryWidth $val');
    if (val == null) {
      throw new ArgumentError();
    }
    if (_mediaQueryWidth != val) {
      _mediaQueryWidth = val;
      notifyListeners();
    }
  }

  double _mediaQueryHeight = 0;

  double get mediaQueryHeight => _mediaQueryHeight;

  set mediaQueryHeight(double val) {
//    log.d('mediaQueryHeight $val');
    if (val == null) {
      throw new ArgumentError();
    }
    if (_mediaQueryHeight != val) {
      _mediaQueryHeight = val;
      notifyListeners();
    }
  }

  double get textScaleFactor {
    return mediaQueryWidth / 411.42857142857144;
  }

  int _lastSelectedRoom = 0;

  int get lastSelectedRoom => _lastSelectedRoom;

  set lastSelectedRoom(int val) {
    if (val == null) {
      throw new ArgumentError();
    }
    if (_lastSelectedRoom != val) {
      _lastSelectedRoom = val;
      notifyListeners();
    }
  }

  String _connectionStatus = '';

  String get connectionStatus => _connectionStatus;

  set connectionStatus(String val) {
    if (val == null) {
      throw new ArgumentError();
    }
    if (_connectionStatus != val) {
      _connectionStatus = val;
//      if (val == "Connected") {
//        gd.getSettings("val == Connected");
//      }
      notifyListeners();
    }
  }

  bool get showSpin {
    if (connectionStatus != 'Connected' &&
        gd.connectionOnDataTime
            .add(Duration(seconds: 10))
            .isBefore(DateTime.now())) {
      return true;
    }
    return false;
  }

  DateTime connectionOnDataTime;

  String _urlTextField = '';

  String get urlTextField => _urlTextField;

  set urlTextField(String val) {
    if (val == null) {
      throw new ArgumentError();
    }
    if (_urlTextField != val) {
      _urlTextField = val;
      notifyListeners();
    }
  }

  void sendHttpPost(String url, String authCode, BuildContext context) async {
    log.d('httpPost $url '
        '\nauthCode $authCode');
    Map<String, String> headers = {
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    var body = 'grant_type=authorization_code'
        '&code=$authCode&client_id=$url/hasskit';
    http
        .post(url + '/auth/token', headers: headers, body: body)
        .then((response) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        gd.connectionStatus =
            'Got response from server with code ${response.statusCode}';

        var bodyDecode = json.decode(response.body);
        var loginData = LoginData.fromJson(bodyDecode);
        loginData.url = url;
//        log.d('bodyDecode $bodyDecode\n'
//            'url ${loginData.url}\n'
//            'longToken ${loginData.longToken}\n'
//            'accessToken ${loginData.accessToken}\n'
//            'expiresIn ${loginData.expiresIn}\n'
//            'refreshToken ${loginData.refreshToken}\n'
//            'tokenType ${loginData.tokenType}\n'
//            'lastAccess ${loginData.lastAccess}\n'
//            '');
        log.d("loginData.url ${loginData.url}");
        log.d("longToken.url ${loginData.longToken}");
        log.d("accessToken.url ${loginData.accessToken}");
        log.d("expiresIn.url ${loginData.expiresIn}");
        log.d("refreshToken.url ${loginData.refreshToken}");
        log.d("tokenType.url ${loginData.tokenType}");
        log.d("lastAccess.url ${loginData.lastAccess}");

        gd.loginDataCurrent = loginData;
        gd.loginDataListAdd(loginData, "sendHttpPost");
        loginDataListSortAndSave("sendHttpPost");
        webSocket.initCommunication();
        gd.connectionStatus =
            'Init Websocket Communication to ${loginDataCurrent.getUrl}';
        log.w(gd.connectionStatus);
        Navigator.pop(context, gd.connectionStatus);
      } else {
        gd.connectionStatus =
            'Error response from server with code ${response.statusCode}';
        Navigator.pop(context, gd.connectionStatus);
      }
    }).catchError((e) {
      gd.connectionStatus = 'Error response from server with code $e';
      Navigator.pop(context, gd.connectionStatus);
    });
  }

  Map<String, Entity> _entities = {};

//  List<Entity> _entities = [];
  UnmodifiableMapView<String, Entity> get entities {
    return UnmodifiableMapView(_entities);
  }

  void socketGetStates(List<dynamic> message) {
//    log.d('socketGetStates $message');

    List<String> previousEntitiesList = entities.keys.toList();

    for (dynamic mess in message) {
      Entity entity = Entity.fromJson(mess);
      if (entity == null || entity.entityId == null) {
        log.e('socketGetStates entity.entityId');
        continue;
      }

//      if (entity.entityId.contains("camera.")) {
//        log.w("\n socketGetStates ${entity.entityId} mess $mess");
//      }

      if (previousEntitiesList.contains(entity.entityId))
        previousEntitiesList.remove(entity.entityId);

      _entities[entity.entityId] = entity;
    }

    if (previousEntitiesList.length > 0) {
      for (String entityId in previousEntitiesList) {
        log.e(
            "Remove $entityId from _entities, it's no longer in recent get_states");
        _entities.remove(entityId);
      }
    }

    log.d('socketGetStates total entities ${_entities.length}');
    notifyListeners();
  }

  void socketSubscribeEvents(dynamic message) {
    String entityId;
    try {
      entityId = message['event']['data']['new_state']["entity_id"];
    } catch (e) {
      log.e("socketSubscribeEvents $e");
      entityId = null;
    }

    if (entityId == null || entityId == "" || entityId == "null") {
      return;
    }

//    log.w(
//        "socketSubscribeEvents new_state ${message['event']['data']['new_state'].toString()}");

    eventEntityUpdate(entityId);
    _entities[entityId] =
        Entity.fromJson(message['event']['data']['new_state']);
    notifyListeners();
  }

  String _eventsEntities;
  String get eventsEntities => _eventsEntities;
  set eventsEntities(String val) {
    if (val != _eventsEntities) {
      _eventsEntities = val;
      notifyListeners();
    }
  }

  Map<String, String> _eventEntity = {};
  String eventEntity(String val) {
    if (_eventEntity[val] == null) {
      return "";
    }
    return _eventEntity[val];
  }

  void eventEntityUpdate(String val) {
    _eventEntity[val] = val + random.nextInt(100).toString();
    notifyListeners();
  }

  bool isEntityNameValid(String entityId) {
    if (entityId == null) {
//      log.d('isEntityNameValid entityName null');
      return false;
    }

    if (!entityId.contains('.')) {
//      log.d('isEntityNameValid $entityId not valid');
      return false;
    }
    return true;
  }

  String processEntityId(String entityId) {
    if (entityId == null) {
      log.e('processEntityId String entityId null');
      return null;
    }

    String entityIdOriginal = entityId;
    entityId = entityId.split(',').first;

    if (!entityId.contains('.')) {
      log.e('processEntityId $entityIdOriginal not valid');
      return null;
    }

    entityId = entityId.replaceAll('{entity: ', '');
    entityId = entityId.replaceAll('}', '');

    return entityId;
  }

  Map<String, CameraInfo> cameraInfos = {};
  List<String> cameraInfosActive = [];
  cameraInfoGet(String entityId) {
    if (!cameraInfos.containsKey(entityId)) {
      cameraInfos[entityId] = CameraInfo(
        entityId: entityId,
        updatedTime: DateTime.now().subtract(Duration(days: 1)),
        requestingTime: DateTime.now().subtract(Duration(days: 1)),
        currentImage: AssetImage("assets/images/loader.png"),
        previousImage: AssetImage("assets/images/loader.png"),
      );
    }
    return cameraInfos[entityId];
  }

  Future<void> cameraInfosUpdate(String entityId) async {
    CameraInfo cameraInfo = gd.cameraInfoGet(entityId);

    if (cameraInfo.requestingTime.isAfter(DateTime.now())) {
//      log.d("updateImage $entityId requestingTime.isAfter");
      return;
    }

//    log.d("CameraInfo.updateImage $entityId");
    cameraInfo.requestingTime = DateTime.now().add(Duration(seconds: 10));
    final url = gd.currentUrl +
        gd.entities[entityId].entityPicture +
        "&time=" +
        DateTime.now().millisecondsSinceEpoch.toString();
    final response = await http.get(url);

    if (response.statusCode == 200) {
      try {
//        log.d(
//            "CameraInfo.updateImage $entityId response.statusCode == 200 url $url");
        cameraInfo.previousImage = cameraInfo.currentImage;
        cameraInfo.currentImage = NetworkImage(url);
        cameraInfo.updatedTime = DateTime.now();
        notifyListeners();
      } catch (e) {
        log.w("CameraInfo.updateImage $entityId catch $e");
      }
    } else {
      log.w(
          "CameraInfo.updateImage $entityId error response.statusCode ${response.statusCode}");
    }
  }

  ThemeData get currentTheme {
    return ThemeInfo.themesData[baseSetting.themeIndex];
  }

  List<LoginData> loginDataList = [];

  int get loginDataListLength {
    return loginDataList.length;
  }

  LoginData loginDataHassKitDemo = LoginData(
    url: "http://hasskitdemo.duckdns.org:8123",
    accessToken:
        "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiI4NWRlNWM4MmE4OGQ0YmYxOTk4ZjgxZGE3YzY3ZWFkNSIsImlhdCI6MTU3MzY5Mzg2NiwiZXhwIjoxNTczNjk1NjY2fQ.GDWWYGshuxPOrv3GMOjqlxKUtPVh5sADzgTUutDp508",
    longToken:
        "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJjZmNkOTk4ZjJiOTE0NjAwOThhNzJlYmQzZTk4NmFhYyIsImlhdCI6MTU3MzY5Mzg2NywiZXhwIjoxNjA1MjI5ODY3fQ.iUOXvErg3B6FyNqIpBZptXzzJSb4ib6E35PJ7XPrtJ4",
    expiresIn: 1800,
    refreshToken:
        "72b2bb75f7363a657031cb3389f1c66a22826154f95fbcd7a6b606a02e797d391898f87b0fef8eff107f35b0f8cc2ad995f3c70d3f609e82ff5f2eec9b0cba3b",
    tokenType: "Bearer",
    lastAccess: 1573693868837,
  );

  LoginData loginDataCurrent = LoginData();

  String _loginDataListString;

  String get loginDataListString => _loginDataListString;

  set loginDataListString(val) {
    if (val == _loginDataListString) return;

    _loginDataListString = val;

    if (_loginDataListString != null && _loginDataListString.length > 0) {
      List<dynamic> loginDataListString = jsonDecode(_loginDataListString);
      loginDataList = [];
      for (var loginData in loginDataListString) {
        LoginData newLoginData = LoginData(
          url: loginData['url'],
          longToken: loginData['longToken'],
          accessToken: loginData['accessToken'],
          expiresIn: loginData['expiresIn'],
          refreshToken: loginData['refreshToken'],
          tokenType: loginData['tokenType'],
          lastAccess: loginData['lastAccess'],
        );
        log.d('loginDataListAdd url ${newLoginData.url}');

        loginDataListAdd(newLoginData, "loginDataListString");
      }
      log.d('loginDataList.length ${loginDataList.length}');
    } else {
      log.w('CAN NOT FIND loginDataList');
    }

    if (gd.loginDataList.length > 0) {
      loginDataCurrent = gd.loginDataList[0];
      if (gd.autoConnect && gd.connectionStatus != "Connected") {
        log.w('Auto connect to ${loginDataCurrent.getUrl}');
        webSocket.initCommunication();
      }
    }
  }

  void loginDataListAdd(LoginData loginData, String from) {
    log.d('LoginData.loginDataListAdd ${loginData.url} from $from');
    var loginDataOld = loginDataList
        .firstWhere((rec) => rec.getUrl == loginData.url, orElse: () => null);
    if (loginDataOld == null) {
      loginDataList.add(loginData);
      log.d('loginDataListAdd ${loginData.url}');
    } else {
      loginDataOld.url = loginData.url;
      loginDataOld.accessToken = loginData.accessToken;
      loginDataOld.longToken = loginData.longToken;
      loginDataOld.expiresIn = loginData.expiresIn;
      loginDataOld.refreshToken = loginData.refreshToken;
      loginDataOld.tokenType = loginData.tokenType;
      loginDataOld.lastAccess = DateTime.now().toUtc().millisecondsSinceEpoch;
      log.e('loginDataListAdd ALREADY HAVE ${loginData.url}');
    }
    notifyListeners();
  }

  void loginDataListSortAndSave(String debug) {
    try {
      if (loginDataList != null && loginDataList.length > 0) {
        loginDataList.sort((a, b) => b.lastAccess.compareTo(a.lastAccess));
        gd.saveString('loginDataList', jsonEncode(loginDataList));
        log.d('loginDataList.length ${loginDataList.length}');
      } else {
        gd.saveString('loginDataList', jsonEncode(loginDataList));
      }
      notifyListeners();
    } catch (e) {
      log.w("loginDataListSortAndSave $e");
    }
  }

  void loginDataListDelete(LoginData loginData) {
    log.d('LoginData.loginDataListDelete ${loginData.url}');
    if (loginData != null) {
      loginDataList.remove(loginData);
      log.d('loginDataList.remove ${loginData.url}');
    } else {
      log.e('loginDataList.remove Can not find ${loginData.url}');
    }
    loginDataListSortAndSave("loginDataListDelete");
  }

  get socketUrl {
    String recVal = loginDataCurrent.url;
    recVal = recVal.replaceAll('http', 'ws');
    recVal = recVal + '/api/websocket';
    return recVal;
  }

  int _socketId = 0;

  get socketId => _socketId;

  set socketId(int value) {
    if (value == null) {
      throw new ArgumentError();
    }
    if (_socketId != value) {
      _socketId = value;
      notifyListeners();
    }
  }

  void socketIdIncrement() {
    socketId = socketId + 1;
  }

  int _subscribeEventsId = 0;

  get subscribeEventsId => _subscribeEventsId;

  set subscribeEventsId(int value) {
    if (value == null) {
      throw new ArgumentError();
    }
    if (_subscribeEventsId != value) {
      _subscribeEventsId = value;
      notifyListeners();
    }
  }

  int _longTokenId = 0;

  get longTokenId => _longTokenId;

  set longTokenId(int value) {
    if (value == null) {
      throw new ArgumentError();
    }
    if (_longTokenId != value) {
      _longTokenId = value;
      notifyListeners();
    }
  }

  int _getStatesId = 0;

  get getStatesId => _getStatesId;

  set getStatesId(int value) {
    if (value == null) {
      throw new ArgumentError();
    }
    if (_getStatesId != value) {
      _getStatesId = value;
      notifyListeners();
    }
  }

//  int _loveLaceConfigId = 0;
//
//  get loveLaceConfigId => _loveLaceConfigId;
//
//  set loveLaceConfigId(int value) {
//    if (value == null) {
//      throw new ArgumentError();
//    }
//    if (_loveLaceConfigId != value) {
//      _loveLaceConfigId = value;
//      notifyListeners();
//    }
//  }

  bool _useSSL = false;

  get useSSL => _useSSL;

  set useSSL(bool value) {
    if (value != true && value != false) {
      throw new ArgumentError();
    }
    if (_useSSL != value) {
      _useSSL = value;
      notifyListeners();
    }
  }

  bool _autoConnect = true;

  get autoConnect => _autoConnect;

  set autoConnect(bool value) {
    if (value != true && value != false) {
      throw new ArgumentError();
    }
    if (_autoConnect != value) {
      _autoConnect = value;
      notifyListeners();
    }
  }

  bool _webViewLoading = false;

  bool get webViewLoading {
    return _webViewLoading;
  }

  set webViewLoading(bool value) {
    if (value != true && value != false) {
      throw new ArgumentError();
    }
    if (_webViewLoading != value) {
      _webViewLoading = value;
      notifyListeners();
    }
  }

//  bool _showLoading = false;
//  bool get showLoading {
//    return _showLoading;
//  }
//
//  set showLoading(bool value) {
//    if (value != true && value != false) {
//      throw new ArgumentError();
//    }
//    if (_showLoading != value) {
//      _showLoading = value;
//      notifyListeners();
//    }
//  }

  String trimUrl(String url) {
    url = url.trim();
    if (url.substring(url.length - 1, url.length) == '/') {
      url = url.substring(0, url.length - 1);
      log.w('$url contain last /');
    }
    return url;
  }

  List<Room> roomList = [];
  List<Room> roomListDefault = [
    Room(
        name: 'Home',
        imageIndex: 12,
        favorites: [],
        entities: [],
        row3: [],
        row4: []),
    Room(
        name: 'Living Room',
        imageIndex: 13,
        favorites: [],
        entities: [],
        row3: [],
        row4: []),
    Room(
        name: 'Kitchen',
        imageIndex: 14,
        favorites: [],
        entities: [],
        row3: [],
        row4: []),
    Room(
        name: 'Bedroom',
        imageIndex: 15,
        favorites: [],
        entities: [],
        row3: [],
        row4: []),
  ];

  List<Room> roomListHassKitDemo = [
    Room(
        name: 'HassKit Demo',
        imageIndex: 12,
        tempEntityId: "sensor.temperature_158d0002e98f27",
        favorites: [
          "WebView1",
          "fan.acorn_fan",
          "climate.air_conditioner_1",
          "cover.cover_06",
          "binary_sensor.motion_sensor_158d000358b1a2",
          "alarm_control_panel.home_alarm",
          "cover.cover_03",
          "fan.living_room_ceiling_fan",
          "light.light_01",
          "lock.lock_9",
          "sensor.humidity_158d0002e98f27",
          "sensor.pressure_158d0002e98f27",
          "sensor.temperature_158d0002e98f27",
          "light.gateway_light_7c49eb891797",
        ],
        entities: [
          "camera.camera_1",
          "camera.camera_2",
        ],
        row3: [
          "switch.socket_sonoff_s20",
          "switch.tuya_neo_coolcam_10a",
        ],
        row4: [
          "climate.air_conditioner_2",
          "climate.air_conditioner_3",
          "climate.air_conditioner_4",
          "climate.air_conditioner_5",
          "fan.kaze_fan",
          "fan.lucci_air_fan",
          "fan.super_fan",
        ]),
    Room(
        name: 'Living Room',
        imageIndex: 13,
        tempEntityId: "sensor.aeotec_temperature_27",
        favorites: [
          "climate.air_conditioner_2",
          "climate.air_conditioner_3",
          "cover.cover_01",
          "cover.cover_02",
          "cover.cover_04",
          "fan.kaze_fan",
          "light.light_03",
          "light.light_02",
          "fan.lucci_air_fan",
          "camera.camera_1",
        ],
        entities: [],
        row3: [],
        row4: []),
    Room(
        name: 'Kitchen',
        imageIndex: 14,
        tempEntityId: "sensor.fibaro_temperature_31",
        favorites: [
          "camera.camera_2",
          "switch.aeotec_motion_26",
          "climate.air_conditioner_4",
          "climate.air_conditioner_5",
          "light.light_04",
          "light.light_05",
          "cover.cover_07",
          "cover.cover_08",
          "fan.super_fan",
          "cover.cover_09",
        ],
        entities: [],
        row3: [],
        row4: []),
    Room(
        name: 'Bedroom',
        imageIndex: 15,
        tempEntityId: "sensor.temperature_158d0002e98f27",
        favorites: [
          "climate.air_conditioner_2",
          "cover.cover_07",
          "cover.cover_08",
          "switch.socket_sonoff_s20",
          "switch.tuya_neo_coolcam_10a",
        ],
        entities: [],
        row3: [],
        row4: []),
  ];

  void roomListClear() {
    roomList.clear();
    roomList = [];
    notifyListeners();
  }

  int get roomListLength {
    if (roomList.length - 1 < 0) {
      return 0;
    }
    return roomList.length - 1;
  }

  String getRoomName(int roomIndex) {
    if (roomList.length > roomIndex && roomList[roomIndex].name != null) {
      return roomList[roomIndex].name;
    }
    return 'HassKit';
  }

  void roomEntitySort(
    int roomIndex,
    int rowNumber,
    String oldEntityId,
    String newEntityId,
  ) {
    log.w('roomEntitySwap oldEntityId $oldEntityId newEntityId $newEntityId');
    var entitiesRef;
    if (rowNumber == 1) {
      entitiesRef = gd.roomList[roomIndex].favorites;
    } else if (rowNumber == 2) {
      entitiesRef = gd.roomList[roomIndex].entities;
    } else if (rowNumber == 3) {
      entitiesRef = gd.roomList[roomIndex].row3;
    } else {
      entitiesRef = gd.roomList[roomIndex].row4;
    }

    int oldIndex = entitiesRef.indexOf(oldEntityId);
    int newIndex = entitiesRef.indexOf(newEntityId);
    String removedString = entitiesRef.removeAt(oldIndex);
    entitiesRef.insert(newIndex, removedString);
    notifyListeners();
    roomListSave(true);
  }

  AssetImage getRoomImage(int roomIndex) {
    if (roomList.length > roomIndex &&
        roomList[roomIndex] != null &&
        roomList[roomIndex].imageIndex != null) {
      return AssetImage(backgroundImage[roomList[roomIndex].imageIndex]);
    }
    return AssetImage(backgroundImage[4]);
  }

  List<String> backgroundImage = [
    'assets/background_images/Dark_Blue.jpg',
    'assets/background_images/Dark_Green.jpg',
    'assets/background_images/Light_Blue.jpg',
    'assets/background_images/Light_Green.jpg',
    'assets/background_images/Orange.jpg',
    'assets/background_images/Red.jpg',
    'assets/background_images/Blue_Gradient.jpg',
    'assets/background_images/Green_Gradient.jpg',
    'assets/background_images/Yellow_Gradient.jpg',
    'assets/background_images/White_Gradient.jpg',
    'assets/background_images/Black_Gradient.jpg',
    'assets/background_images/Light_Pink.jpg',
    'assets/background_images/Abstract_1.jpg',
    'assets/background_images/Abstract_2.jpg',
    'assets/background_images/Abstract_3.jpg',
    'assets/background_images/Abstract_4.jpg',
    'assets/background_images/Abstract_5.jpg',
  ];

  setRoomBackgroundImage(Room room, int backgroundImageIndex) {
    if (room.imageIndex != backgroundImageIndex) {
      room.imageIndex = backgroundImageIndex;
      notifyListeners();
    }
    roomListSave(true);
  }

  setRoomName(Room room, String name) {
    log.w('setRoomName room.name ${room.name} name $name');
    if (room.name != name) {
      room.name = name;
      notifyListeners();
    }
    roomListSave(true);
  }

  setRoomBackgroundAndName(Room room, int backgroundImageIndex, String name) {
    setRoomBackgroundImage(room, backgroundImageIndex);
    setRoomName(room, name);
  }

  deleteRoom(int roomIndex) async {
    log.w('deleteRoom roomIndex $roomIndex');
    if (roomList.length > roomIndex) {
      pageController.animateToPage(
        roomIndex,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
      await Future.delayed(const Duration(milliseconds: 500));
      roomList.removeAt(roomIndex);
      pageController.jumpToPage(roomIndex - 1);
      notifyListeners();
    }
    roomListSave(true);
  }

  PageController pageController;

  addRoom(int fromPageIndex) async {
    log.w('addRoom');
    var millisecondsSinceEpoch =
        DateTime.now().millisecondsSinceEpoch.toString();
    millisecondsSinceEpoch = millisecondsSinceEpoch.substring(
        millisecondsSinceEpoch.length - 4, millisecondsSinceEpoch.length);
    var newRoom = Room(
      name: 'Room ' + millisecondsSinceEpoch,
      imageIndex: random.nextInt(gd.backgroundImage.length),
      favorites: [],
      entities: [],
      row3: [],
      row4: [],
    );

    roomList.insert(fromPageIndex + 1, newRoom);
    pageController.animateToPage(
      fromPageIndex,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );

    roomListSave(true);
    notifyListeners();
  }

  notify() {
    notifyListeners();
  }

  swapRoom(int oldRoomIndex, int newRoomIndex) {
    if (oldRoomIndex == newRoomIndex) {
      log.e('oldRoomIndex==newRoomIndex');
      return;
    }

    log.w('swapRoom oldRoomIndex $oldRoomIndex newRoomIndex $newRoomIndex');

    Room oldRoom = roomList[oldRoomIndex];
    roomList.remove(oldRoom);
    roomList.insert(newRoomIndex, oldRoom);

    pageController.animateToPage(newRoomIndex - 1,
        duration: Duration(milliseconds: 500), curve: Curves.ease);

    roomListSave(true);
    notifyListeners();
  }

  Timer _roomListSaveTimer;

  void roomListSave(bool saveFirebase) {
    notifyListeners();
    _roomListSaveTimer?.cancel();
    _roomListSaveTimer = null;
    _roomListSaveTimer = Timer(Duration(seconds: 5), () {
      roomListSaveActually(saveFirebase);
    });
  }

  void roomListSaveActually(bool saveFirebase) {
    log.d("roomListSaveActually $saveFirebase");
    _roomListSaveTimer?.cancel();
    _roomListSaveTimer = null;
    try {
      var url = gd.loginDataCurrent.getUrl.replaceAll(".", "-");
      url = url.replaceAll("/", "-");
      url = url.replaceAll(":", "-");
      gd.saveString('roomList $url', jsonEncode(roomList));
      if (saveFirebase) roomListSaveFirebase();
      log.w('roomListSave $url roomList.length ${roomList.length}');
    } catch (e) {
      log.w("roomListSave $e");
    }
  }

  void roomListSaveFirebase() async {
    var url = gd.loginDataCurrent.getUrl.replaceAll(".", "-");
    url = url.replaceAll("/", "-");
    url = url.replaceAll(":", "-");
    if (gd.firebaseUser != null) {
      log.w(
          'roomListSaveFirebase roomListSave $url roomList.length ${roomList.length}');

      Firestore.instance
          .collection('UserData')
          .document('${gd.firebaseUser.uid}')
          .updateData(
        {
          'roomList $url': jsonEncode(roomList),
        },
      );
    }
  }

  String _roomListString;

  String get roomListString => _roomListString;

  set roomListString(val) {
    if (_roomListString != val) {
      _roomListString = val;

      if (_roomListString != null && _roomListString.length > 0) {
        log.w('FOUND _roomListString $_roomListString');
//        List<dynamic> roomListJson = jsonDecode(_roomListString);

        roomList.clear();
        roomList = [];

        var roomListJson = jsonDecode(_roomListString);

        log.w("roomListJson $roomListJson");

        for (var roomJson in roomListJson) {
          Room room = Room.fromJson(roomJson);
          log.d('addRoom ${room.name}');
          roomList.add(room);
        }
        log.d('loginDataList.length ${roomList.length}');
      }
//      else if(currentUrl)
//        {
//
//        }
      else {
        log.w('CAN NOT FIND roomList adding default data');
        roomList.clear();
        roomList = [];
        gd.roomListString = "";
        for (var room in roomListDefault) {
          roomList.add(room);
        }
      }

      notifyListeners();
    }
  }

//  loadRoomListAsync(String url) async {
//    url = base64Url.encode(utf8.encode(url));
//    roomListString = await gd.getString('roomList $url');
//  }

  var emptySliver = SliverFixedExtentList(
    itemExtent: 0,
    delegate: SliverChildListDelegate(
      [],
    ),
  );

  String textToDisplay(String text) {
    text = text.replaceAll('_', ' ');
    text = text.replaceAll('  ', ' ');

    var splits = text.split(" ");
    var recVal = "";
    for (int i = 0; i < splits.length; i++) {
      var split = splits[i];
      if (split.length > 1) {
        recVal = recVal + split[0].toUpperCase() + split.substring(1) + " ";
      } else if (split.length > 0) {
        recVal = recVal + split[0].toUpperCase() + " ";
      } else {
        recVal = recVal + '???' + " ";
      }
    }
    return recVal;
//    if (text.length > 1) {
//      return text[0].toUpperCase() + text.substring(1);
//    } else if (text.length > 0) {
//      return text[0].toUpperCase();
//    } else {
//      return '???';
//    }
  }

//  Map<String, String> toggleStatusMap = {};

  void toggleStatus(Entity entity) {
//    toggleStatusMap[entity.entityId] = random.nextInt(10).toString();
//    log.d("toggleStatusMap ${toggleStatusMap.values.toList()}");
    if (entity.entityType != EntityType.lightSwitches &&
        entity.entityType != EntityType.scriptAutomation &&
        entity.entityType != EntityType.climateFans &&
        entity.entityType != EntityType.mediaPlayers &&
        entity.entityType != EntityType.group) {
      return;
    }

    log.w("toggleStatus ${entity.entityId}");
    eventEntity(entity.entityId);
    delayGetStatesTimer(5);
    entity.toggleState();
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  Map<String, bool> clickedStatus = {};
  bool getClickedStatus(String entityId) {
    if (clickedStatus[entityId] != null) return clickedStatus[entityId];
    return false;
  }

  void setState(Entity entity, String state, String message) {
    entity.state = state;
    delayGetStatesTimer(5);
    webSocket.send(message);
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  void setFanSpeed(Entity entity, String speed, String message) {
    delayGetStatesTimer(5);
    entity.speed = speed;
    entity.state = "on";
    webSocket.send(message);
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  void setFanOscillating(Entity entity, bool oscillating, String message) {
    delayGetStatesTimer(5);
    entity.oscillating = oscillating;
    webSocket.send(message);
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  void sendSocketMessage(message) {
//    log.d("sendSocketMessage $outMsg");
    webSocket.send(message);
    HapticFeedback.mediumImpact();
    gd.delayGetStatesTimer(5);
  }

  Timer _sendSocketMessageDelay;

  void sendSocketMessageDelay(outMsg, int delay) {
    _sendSocketMessageDelay?.cancel();
    _sendSocketMessageDelay = null;
    _sendSocketMessageDelay = Timer(Duration(seconds: delay), () {
      sendSocketMessage(outMsg);
    });
  }

  Timer _delayGetStates;

  void delayGetStatesTimer(int seconds) {
    _delayGetStates?.cancel();
    _delayGetStates = null;

//    _delayGetStates = Timer(Duration(seconds: seconds), delayGetStates);
    _delayGetStates = Timer(Duration(seconds: seconds), httpApiStates);
  }

  void delayGetStates() {
    var outMsg = {'id': gd.socketId, 'type': 'get_states'};
    var message = jsonEncode(outMsg);
    webSocket.send(message);
    gd.connectionStatus = 'Sending get_states';
    log.w('delayGetStates!');
  }

  List<String> get entitiesInRoomsExceptDefault {
    List<String> recVal = [];
    for (int i = 0; i < roomList.length - 2; i++) {
      recVal = recVal + roomList[i].entities;
    }
    return recVal;
  }

  void removeEntityInRoom(String entityId, int roomIndex, String friendlyName,
      BuildContext context) {
    log.w('removeEntityInRoom $entityId roomIndex $roomIndex');
    if (gd.roomList[roomIndex].entities.contains(entityId)) {
      gd.roomList[roomIndex].entities.remove(entityId);
      notifyListeners();
      Flushbar(
//        title: "Require Slide to Open",
        message: "Removed $friendlyName from ${roomList[roomIndex].name}",
        duration: Duration(seconds: 3),
      )..show(context);
      roomListSave(true);
    }
    delayCancelEditModeTimer(300);
  }

  void showEntityInRoom(String entityId, int roomIndex, String friendlyName,
      BuildContext context) {
    log.w('showEntityInRoom $entityId roomIndex $roomIndex');
    if (!gd.roomList[roomIndex].entities.contains(entityId)) {
      gd.roomList[roomIndex].entities.add(entityId);
      notifyListeners();
      Flushbar(
//        title: "Require Slide to Open",
        message: "Added $friendlyName to ${roomList[roomIndex].name}",
        duration: Duration(seconds: 3),
      )..show(context);
      roomListSave(true);
    }
    delayCancelEditModeTimer(300);
  }

  IconData climateModeToIcon(String text) {
    text = text.toLowerCase();
    if (text.contains('off')) {
      return MaterialDesignIcons.getIconDataFromIconName('mdi:power');
    }
    if (text.contains('cool')) {
      return MaterialDesignIcons.getIconDataFromIconName('mdi:snowflake');
    }
    if (text.contains('heat')) {
      return MaterialDesignIcons.getIconDataFromIconName('mdi:weather-sunny');
    }
    if (text.contains('fan')) {
      return MaterialDesignIcons.getIconDataFromIconName('mdi:fan');
    }
    return MaterialDesignIcons.getIconDataFromIconName('mdi:thermometer');
  }

  Color climateModeToColor(String text) {
    text = text.toLowerCase();
    if (text.contains('off')) {
      return ThemeInfo.colorBottomSheetReverse.withOpacity(0.75);
    }
    if (text.contains('heat')) {
      return Colors.red;
    }
    if (text.contains('cool')) {
      return Colors.green;
    }
    return Colors.amber;
  }

  ViewMode _viewMode = ViewMode.normal;

  get viewMode => _viewMode;

  set viewMode(ViewMode viewMode) {
    if (viewMode == ViewMode.edit) {
      delayCancelEditModeTimer(300);
    }
    if (viewMode == ViewMode.sort) {
      delayCancelSortModeTimer(300);
    }
    if (_viewMode != viewMode) {
      _viewMode = viewMode;
      notifyListeners();
    }
  }

  Timer _delayCancelSortMode;

  void delayCancelSortModeTimer(int seconds) {
    _delayCancelSortMode?.cancel();
    _delayCancelSortMode = null;

    _delayCancelSortMode =
        Timer(Duration(seconds: seconds), delayCancelSortMode);
  }

  void delayCancelSortMode() {
    viewMode = ViewMode.normal;
    log.w('delayCancelSortMode!');
  }

  void toggleSortMode() {
    if (viewMode == ViewMode.sort) {
      viewMode = ViewMode.normal;
    } else {
      viewMode = ViewMode.sort;
    }
    notifyListeners();
  }

  Timer _delayCancelEditMode;

  void delayCancelEditModeTimer(int seconds) {
    _delayCancelEditMode?.cancel();
    _delayCancelEditMode = null;

    _delayCancelEditMode =
        Timer(Duration(seconds: seconds), delayCancelEditMode);
  }

  void delayCancelEditMode() {
    viewMode = ViewMode.normal;
    log.w('delayCancelEditMode!');
  }

  void toggleEditMode() {
    if (viewMode == ViewMode.edit) {
      viewMode = ViewMode.normal;
    } else {
      viewMode = ViewMode.edit;
    }
    notifyListeners();
  }

  String entityTypeCombined(String entityId) {
    entityId = entityId.split('.').first;
    if (entityId.contains('fan.') || entityId.contains('climate.')) {
      return 'climateFans';
    } else if (entityId.contains('camera.')) {
      return 'cameras';
    } else if (entityId.contains('media_player.')) {
      return 'mediaPlayers';
    } else if (entityId.contains('script.') ||
        entityId.contains('automation.')) {
      return 'scriptAutomation';
    } else if (entityId.contains('light.') ||
        entityId.contains('switch.') ||
        entityId.contains('cover.') ||
        entityId.contains('input_boolean.') ||
        entityId.contains('lock.') ||
        entityId.contains('vacuum.')) {
      return 'lightSwitches';
    } else {
      return 'accessories';
    }
  }

  double mapNumber(
      double x, double inMin, double inMax, double outMin, double outMax) {
    return (x - inMin) * (outMax - outMin) / (inMax - inMin) + outMin;
  }

  int colorCap(int x, int inMin, int inMax) {
    if (x < inMin) {
      return inMin;
    }
    if (x > inMax) {
      return inMax;
    }
    return x;
  }

//  List<String> requireSlideToOpen = [];

  void requireSlideToOpenAddRemove(String entityId) {
    if (gd.entitiesOverride[entityId] != null &&
        gd.entitiesOverride[entityId].openRequireAttention != null &&
        gd.entitiesOverride[entityId].openRequireAttention == true) {
      gd.entitiesOverride[entityId].openRequireAttention = false;
    } else {
      var entitiesOverride = gd.entitiesOverride[entityId];
      if (entitiesOverride == null) entitiesOverride = new EntityOverride();
      entitiesOverride.openRequireAttention = true;
      gd.entitiesOverride[entityId] = entitiesOverride;
    }
    notifyListeners();
    entitiesOverrideSave(true);
  }

  BaseSetting baseSetting = BaseSetting(
      itemsPerRow: 3,
      themeIndex: 1,
      lastArmType: "arm_home",
      notificationDevices: [],
      colorPicker: [
        "0xffEEEEEE",
        "0xffEF5350",
        "0xffFFCA28",
        "0xff66BB6A",
        "0xff42A5F5",
        "0xffAB47BC",
      ]);
  String _baseSettingString;

  String get baseSettingString => _baseSettingString;

  set baseSettingString(val) {
    if (_baseSettingString != val) {
      _baseSettingString = val;

      if (_baseSettingString != null && _baseSettingString.length > 0) {
        log.w('FOUND _baseSettingString $_baseSettingString');

        val = jsonDecode(val);
        baseSetting = BaseSetting.fromJson(val);
      } else {
        log.w('CAN NOT FIND baseSetting adding default data');
        baseSetting.itemsPerRow = 3;
        baseSetting.themeIndex = 1;
        baseSetting.lastArmType = "arm_away";
        baseSetting.notificationDevices = [];
        baseSetting.colorPicker = [
          "0xffEEEEEE",
          "0xffEF5350",
          "0xffFFCA28",
          "0xff66BB6A",
          "0xff42A5F5",
          "0xffAB47BC",
        ];
      }
      notifyListeners();
    }
  }

  Timer _baseSettingSaveTimer;

  void baseSettingSave(bool saveFirebase) {
    notifyListeners();
    _baseSettingSaveTimer?.cancel();
    _baseSettingSaveTimer = null;
    _baseSettingSaveTimer = Timer(Duration(seconds: 5), () {
      baseSettingSaveActually(saveFirebase);
    });
  }

  void baseSettingSaveActually(bool saveFirebase) {
    log.d("baseSettingSaveActually $saveFirebase");

    try {
      var jsonBaseSetting = {
        'itemsPerRow': baseSetting.itemsPerRow,
        'themeIndex': baseSetting.themeIndex,
        'lastArmType': baseSetting.lastArmType,
        'notificationDevices': baseSetting.notificationDevices,
        'colorPicker': baseSetting.colorPicker,
        'webView1Ratio': baseSetting.webView1Ratio,
        'webView1Url': baseSetting.webView1Url,
        'webView2Ratio': baseSetting.webView2Ratio,
        'webView2Url': baseSetting.webView2Url,
        'webView3Ratio': baseSetting.webView3Ratio,
        'webView3Url': baseSetting.webView3Url,
      };

      var url = gd.loginDataCurrent.getUrl.replaceAll(".", "-");
      url = url.replaceAll("/", "-");
      url = url.replaceAll(":", "-");

      gd.saveString('baseSetting $url', jsonEncode(jsonBaseSetting));
      log.w('save baseSetting $url $jsonBaseSetting');

      if (saveFirebase) baseSettingSaveFirebase();
    } catch (e) {
      log.w("baseSettingSave $e");
    }
    notifyListeners();
  }

  BaseSetting baseSettingHassKitDemo = BaseSetting(
    themeIndex: 1,
    itemsPerRow: 3,
    lastArmType: "arm_away",
    colorPicker: [
      "0xffEEEEEE",
      "0xffEF5350",
      "0xffFFCA28",
      "0xff66BB6A",
      "0xff42A5F5",
      "0xffAB47BC",
    ],
    notificationDevices: [
      "fan.acorn_fan",
      "climate.air_conditioner_1",
      "cover.cover_06",
      "binary_sensor.motion_sensor_158d000358b1a2",
      "binary_sensor.motion_sensor_158d0002f1d1d2",
      "cover.cover_03",
      "light.light_01",
      "lock.lock_9",
      "light.gateway_light_7c49eb891797",
      "switch.socket_sonoff_s20",
      "switch.tuya_neo_coolcam_10a",
      "climate.air_conditioner_2",
      "climate.air_conditioner_3",
      "climate.air_conditioner_4",
      "climate.air_conditioner_5",
      "fan.kaze_fan",
      "fan.lucci_air_fan",
      "fan.super_fan",
    ],
  );

  void baseSettingSaveFirebase() {
    if (gd.firebaseUser != null) {
      var url = gd.loginDataCurrent.getUrl.replaceAll(".", "-");
      url = url.replaceAll("/", "-");
      url = url.replaceAll(":", "-");

      var jsonBaseSetting = baseSetting.toJson();

      log.w('baseSettingSaveFirebase $url');
      Firestore.instance
          .collection('UserData')
          .document('${gd.firebaseUser.uid}')
          .updateData(
        {
          'baseSetting $url': jsonEncode(jsonBaseSetting),
        },
      );
    }
  }

  Map<String, EntityOverride> entitiesOverride = {};
  String _entitiesOverrideString;

  String get entitiesOverrideString => _entitiesOverrideString;

  set entitiesOverrideString(val) {
    if (_entitiesOverrideString != val) {
      _entitiesOverrideString = val;

      if (_entitiesOverrideString != null &&
          _entitiesOverrideString.length > 0) {
        log.w('FOUND _entitiesOverrideString $_entitiesOverrideString');
        entitiesOverride = {};

        Map<String, dynamic> entitiesOverrideJson =
            jsonDecode(entitiesOverrideString);

        for (var entityOverrideJson in entitiesOverrideJson.keys) {
          var entitiesOverrideId = entityOverrideJson;
          var entitiesOverrideIdList = entitiesOverrideJson[entitiesOverrideId];
          entitiesOverride[entitiesOverrideId] =
              EntityOverride.fromJson(entitiesOverrideIdList);
        }
        log.d('entitiesOverride.length ${entitiesOverride.length}');
      } else {
        log.w('CAN NOT FIND entitiesOverride');
        entitiesOverride = {};
      }

      notifyListeners();
    }
  }

  Timer _entitiesOverrideSaveTimer;

  void entitiesOverrideSave(bool saveFirebase) {
    notifyListeners();
    _entitiesOverrideSaveTimer?.cancel();
    _entitiesOverrideSaveTimer = null;
    _entitiesOverrideSaveTimer = Timer(Duration(seconds: 5), () {
      entitiesOverrideSaveActually(saveFirebase);
    });
  }

  void entitiesOverrideSaveActually(bool saveFirebase) {
    log.d("entitiesOverrideSaveActually $saveFirebase");

    try {
      Map<String, EntityOverride> entitiesOverrideClean = {};

      for (var key in gd.entitiesOverride.keys) {
        var entityOverrideClean = gd.entitiesOverride[key];
        if (entityOverrideClean.friendlyName != null &&
                entityOverrideClean.friendlyName.length > 0 ||
            entityOverrideClean.icon != null &&
                entityOverrideClean.icon.length > 0 ||
            entityOverrideClean.openRequireAttention != null &&
                entityOverrideClean.openRequireAttention == true) {
          entitiesOverrideClean[key] = entityOverrideClean;
        }
      }
      entitiesOverride = entitiesOverrideClean;
      gd.saveString('entitiesOverride', jsonEncode(entitiesOverride));
      log.w('save entitiesOverride.length ${entitiesOverride.length}');
      if (saveFirebase) entitiesOverrideSaveFirebase();
    } catch (e) {
      log.w("entitiesOverrideSave $e");
    }
    notifyListeners();
  }

  void entitiesOverrideSaveFirebase() {
    if (gd.firebaseUser != null) {
      log.w(
          'entitiesOverrideSaveFirebase entitiesOverride.length ${entitiesOverride.length}');

      Firestore.instance
          .collection('UserData')
          .document('${gd.firebaseUser.uid}')
          .updateData(
        {
          'entitiesOverride': jsonEncode(entitiesOverride),
        },
      );
    }
  }

  List<String> iconsOverride = [
    "",
    "mdi:account",
    "mdi:air-conditioner",
    "mdi:air-filter",
    "mdi:air-horn",
    "mdi:air-purifier",
    "mdi:airplay",
    "mdi:alert",
    "mdi:alert-outline",
    "mdi:battery-80",
    "mdi:bell",
    "mdi:blinds",
    "mdi:blur",
    "mdi:blur-linear",
    "mdi:blur-off",
    "mdi:blur-radial",
    "mdi:brightness-5",
    "mdi:brightness-7",
    "mdi:camera",
    "mdi:candle",
    "mdi:candycane",
    "mdi:cast",
    "mdi:ceiling-light",
    "mdi:check-outline",
    "mdi:checkbox-blank-circle-outline",
    "mdi:checkbox-marked-circle",
    "mdi:desk-lamp",
    "mdi:dip-switch",
    "mdi:doorbell-video",
    "mdi:door-closed",
    "mdi:fan",
    "mdi:fire",
    "mdi:flash",
    "mdi:floor-lamp",
    "mdi:flower",
    "mdi:garage",
    "mdi:gauge",
    "mdi:group",
    "mdi:home",
    "mdi:home-automation",
    "mdi:home-outline",
    "mdi:lamp",
    "mdi:lava-lamp",
    "mdi:leaf",
    "mdi:light-switch",
    "mdi:lightbulb",
    "mdi:lightbulb-off",
    "mdi:lightbulb-off-outline",
    "mdi:lightbulb-outline",
    "mdi:lighthouse",
    "mdi:lighthouse-on",
    "mdi:lock",
    "mdi:music-note",
    "mdi:music-note-off",
    "mdi:page-layout-sidebar-right",
    "mdi:pine-tree",
    "mdi:power",
    "mdi:power-cycle",
    "mdi:power-off",
    "mdi:power-on",
    "mdi:power-plug",
    "mdi:power-plug-off",
    "mdi:power-settings",
    "mdi:power-sleep",
    "mdi:power-socket",
    "mdi:power-socket-au",
    "mdi:power-socket-eu",
    "mdi:power-socket-uk",
    "mdi:power-socket-us",
    "mdi:power-standby",
    "mdi:radiator",
    "mdi:robot-vacuum",
    "mdi:script-text",
    "mdi:server-network",
    "mdi:server-network-off",
    "mdi:shield-check",
    "mdi:snowflake",
    "mdi:speaker",
    "mdi:square",
    "mdi:square-outline",
    "mdi:theater",
    "mdi:thermometer",
    "mdi:thermostat",
    "mdi:timer",
    "mdi:toggle-switch",
    "mdi:toggle-switch-off",
    "mdi:toggle-switch-off-outline",
    "mdi:toggle-switch-outline",
    "mdi:track-light",
    "mdi:vibrate",
    "mdi:video-switch",
    "mdi:walk",
    "mdi:wall-sconce",
    "mdi:wall-sconce-flat",
    "mdi:wall-sconce-variant",
    "mdi:water",
    "mdi:water-off",
    "mdi:water-percent",
    "mdi:weather-partlycloudy",
    "mdi:webcam",
    "mdi:white-balance-incandescent",
    "mdi:white-balance-iridescent",
    "mdi:white-balance-sunny",
    "mdi:window-closed",
    "mdi:window-shutter",
  ];

  IconData mdiIcon(String iconString) {
    try {
      return MaterialDesignIcons.getIconDataFromIconName(iconString);
    } catch (e) {
      log.e("mdiIcon $e");
      return MaterialDesignIcons.getIconDataFromIconName("help-box");
    }
  }

  String getNulString(String input) {
    try {
      return input;
    } catch (e) {
      return "";
    }
  }

  int getNullInt(int input) {
    if (input == null) {
      return 0;
    }
    return input;
  }

  AppLifecycleState _lastLifecycleState;

  AppLifecycleState get lastLifecycleState => _lastLifecycleState;

  set lastLifecycleState(AppLifecycleState val) {
    if (_lastLifecycleState != val) {
      _lastLifecycleState = val;
      notifyListeners();
    }
  }

  FirebaseUser _firebaseUser;
  FirebaseUser get firebaseUser => _firebaseUser;
  set firebaseUser(FirebaseUser val) {
    if (_firebaseUser != val) {
      log.e("_firebaseUser != val _firebaseUser $_firebaseUser val $val");
      _firebaseUser = val;
      getSettings("_firebaseUser != null");
      createFirebaseDocument();
      getStreamData();
      notifyListeners();
    }
  }

  void createFirebaseDocument() async {
    if (_firebaseUser != null) {
      log.d(
          "_firebaseUser uid ${_firebaseUser.uid} email ${_firebaseUser.email} "
          "photoUrl ${_firebaseUser.photoUrl} phoneNumber ${_firebaseUser.phoneNumber} displayName ${_firebaseUser.displayName}");

      Firestore.instance
          .collection('UserData')
          .document('${gd.firebaseUser.uid}')
          .get()
          .then(
        (DocumentSnapshot ds) {
          // use ds as a snapshot
//            log.d("ds.exists ${ds.exists}");
          if (!ds.exists) {
            Firestore.instance
                .collection('UserData')
                .document('${gd.firebaseUser.uid}')
                .setData(
              {
                'created': DateTime.now(),
              },
            );
          }
        },
      );
    }
  }

  Future<void> assignFirebaseUser(
      GoogleSignInAccount googleSignInAccount) async {
    try {
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.getCredential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final AuthResult authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);
      gd.firebaseUser = authResult.user;
    } catch (error) {
      print(error);
    }
  }

  GoogleSignInAccount _googleSignInAccount;
  GoogleSignInAccount get googleSignInAccount => _googleSignInAccount;

  set googleSignInAccount(GoogleSignInAccount googleSignInAccount) {
    if (_googleSignInAccount != googleSignInAccount) {
      _googleSignInAccount = googleSignInAccount;
      log.w("_firebaseCurrentUser != firebaseCurrentUser");

      if (googleSignInAccount != null) {
        log.w("get the FirebaseUser");
        assignFirebaseUser(googleSignInAccount);
      } else {
        firebaseUser = null;
      }
      log.e("googleSignInAccount notifyListeners");
      notifyListeners();
    }
  }

  Stream<DocumentSnapshot> snapshots;

  getStreamData() async {
    if (firebaseUser != null) {
      gd.snapshots = Firestore.instance
          .collection('UserData')
          .document("${firebaseUser.uid}")
          .snapshots();

      if (gd.snapshots != null) {
        await for (var documents in gd.snapshots) {
          if (firebaseUser != null && documents.data != null) {
            log.d("getStreamData streamData ${documents.data.length}");

            var url = gd.loginDataCurrent.getUrl.replaceAll(".", "-");
            url = url.replaceAll("/", "-");
            url = url.replaceAll(":", "-");

            gd.entitiesOverrideString = documents.data["entitiesOverride"];

            gd.baseSettingString = documents.data["baseSetting $url"];

            gd.roomListString = documents.data["roomList $url"];
          }
        }
      }
    } else {
      gd.snapshots = null;
    }
  }

  getSettings(String reason) async {
    log.e("getSettings FROM $reason");
    //NO URL return empty data

    if (loginDataList.length < 1) {
      loginDataList.add(loginDataHassKitDemo);
      loginDataCurrent = loginDataHassKitDemo;
    }

    if (!gd.autoConnect ||
        gd.currentUrl == "" ||
        gd.loginDataCurrent.url == null ||
        !isURL(gd.loginDataCurrent.url, protocols: ['http', 'https'])) {
      log.e("getSettings gd.autoConnect");
      gd.roomList = [];
      gd.entitiesOverride = {};
      return;
    }

    //no firebase return load disk data
    if (gd.firebaseUser == null) {
      log.e("gd.firebaseUser == null");
      var url = gd.loginDataCurrent.getUrl.replaceAll(".", "-");
      url = url.replaceAll("/", "-");
      url = url.replaceAll(":", "-");
      //force the trigger reset
      gd.entitiesOverrideString = "";
      gd.entitiesOverrideString = await gd.getString('entitiesOverride');
      //force the trigger reset
      gd.baseSettingString = "";
      gd.baseSettingString = await gd.getString('baseSetting $url');
      if (gd.baseSettingString == null || gd.baseSettingString.length < 1) {
        log.w(
            "gd.baseSettingString == null || gd.baseSettingString.length < 1");
        if (gd.currentUrl == "http://hasskitdemo.duckdns.org:8123") {
          log.w(
              "gd.baseSettingString currentUrl == http://hasskitdemo.duckdns.org:8123");
          gd.baseSettingString = jsonEncode(gd.baseSettingHassKitDemo);
        }
      }
      //force the trigger reset
      gd.roomListString = "";
      gd.roomListString = await gd.getString('roomList $url');
      if (gd.roomListString == null || gd.roomListString.length < 1) {
        if (gd.currentUrl == "http://hasskitdemo.duckdns.org:8123") {
          gd.roomListString = jsonEncode(gd.roomListHassKitDemo);
        } else {
          gd.roomListString = jsonEncode(gd.roomListDefault);
        }
      }
      return;
    }

    log.e("gd.firebaseCurrentUser != null");

    downloadCloudData();
  }

  void downloadCloudData() async {
    log.w("getCloudData");
    Firestore.instance
        .collection('UserData')
        .document('${gd.firebaseUser.uid}')
        .get()
        .then(
      (DocumentSnapshot ds) {
        log.e("gd.firebaseCurrentUser != null ds.exists");
        var url = gd.loginDataCurrent.getUrl.replaceAll(".", "-");
        url = url.replaceAll("/", "-");
        url = url.replaceAll(":", "-");

        //force the trigger reset
        gd.entitiesOverrideString = "";
        gd.entitiesOverrideString = ds["entitiesOverride"];

        //force the trigger reset
        gd.baseSettingString = "";
        gd.baseSettingString = ds['baseSetting $url'];
        //force the trigger reset
        gd.roomListString = "";
        gd.roomListString = ds['roomList $url'];

        if (gd.roomListString == null || gd.roomListString.length < 1) {
          if (gd.currentUrl == "http://hasskitdemo.duckdns.org:8123") {
            gd.roomListString = json.encode(gd.roomListHassKitDemo);
          } else {
            gd.roomListString = json.encode(gd.roomListDefault);
          }
        }
        if (gd.baseSetting == null) {
          if (gd.currentUrl == "http://hasskitdemo.duckdns.org:8123") {
            gd.baseSetting = gd.baseSettingHassKitDemo;
          }
        }
      },
    );

    await Future.delayed(const Duration(milliseconds: 5000));

    roomListSave(false);
    entitiesOverrideSave(false);
    baseSettingSave(false);
  }

  void uploadCloudData() async {
    baseSettingSaveFirebase();
    roomListSaveFirebase();
    entitiesOverrideSaveFirebase();
  }

  void deleteCloudData() async {
    var adaRef = Firestore.instance
        .collection('UserData')
        .document('${gd.firebaseUser.uid}');
    await adaRef.delete();
    createFirebaseDocument();
  }

  String _currentUrl = "";
  String get currentUrl => _currentUrl;
  set currentUrl(String val) {
    if (val != _currentUrl) {
      _currentUrl = val;
      if (_currentUrl != "") {
        getSettings("currentUrl");
      }
      notifyListeners();
    }
  }

  int _cameraStreamId = 0;

  int get cameraStreamId => _cameraStreamId;

  set cameraStreamId(int val) {
    if (val == null) {
      throw new ArgumentError();
    }
    if (_cameraStreamId != val) {
      _cameraStreamId = val;
      notifyListeners();
    }
  }

  String _cameraStreamUrl = "";

  String get cameraStreamUrl => _cameraStreamUrl;

  set cameraStreamUrl(String val) {
    if (_cameraStreamUrl != val) {
      _cameraStreamUrl = val;
      notifyListeners();
    }
  }

  void requestCameraStream(String entityId) {
    try {
      if (gd.cameraStreamId == 0 && gd.cameraStreamUrl == "") {
        gd.cameraStreamId = gd.socketId;
        var outMsg = {
          "id": gd.cameraStreamId,
          "type": "camera/stream",
          "format": "hls",
          "entity_id": entityId,
        };

        var message = jsonEncode(outMsg);
        webSocket.send(message);
        log.d("requestCameraStream ${jsonEncode(outMsg)}");
      }
    } catch (e) {
      log.e("requestCameraStream $entityId $e");
    }
  }

  List<Sensor> sensors = [];

  String classDefaultIcon(String deviceClass) {
    deviceClass = deviceClass.replaceAll(".", "");
    switch (deviceClass) {
      case "alarm_control_panel":
        return "mdi:shield";
      case "automation":
        return "mdi:home-automation";
      case "binary_sensor":
        return "mdi:run";
      case "camera":
        return "mdi:webcam";
      case "climate":
        return "mdi:thermostat";
      case "cover":
        return "mdi:garage-open";
      case "fan":
        return "mdi:fan";
      case "input_number":
        return "mdi:pan-vertical";
      case "light":
        return "mdi:lightbulb-on";
      case "lock":
        return "mdi:lock-open";
      case "media_player":
        return "mdi:theater";
      case "person":
        return "mdi:account";
      case "sun":
        return "mdi:white-balance-sunny";
      case "switch":
        return "mdi:toggle-switch";
      case "timer":
        return "mdi:timer";
      case "vacuum":
        return "mdi:robot-vacuum";
      case "weather":
        return "mdi:weather-partlycloudy";
      default:
        return "";
    }
  }

  List<Entity> get activeDevicesOn {
    List<Entity> entities = [];
    for (String notificationDevice in baseSetting.notificationDevices) {
      if (gd.entities[notificationDevice] != null &&
          gd.entities[notificationDevice].isStateOn) {
        entities.add(gd.entities[notificationDevice]);
      }
    }
    return entities;
  }

  bool activeDevicesSupportedType(String entityId) {
    if (entityId.contains("light.") ||
        entityId.contains("switch.") ||
        entityId.contains("cover.") ||
        entityId.contains("lock.") ||
        entityId.contains("fan.") ||
        entityId.contains("climate.") ||
//        entityId.contains("group.") ||
        entityId.contains("media_player.") ||
        entityId.contains("input_boolean.") ||
        entityId.contains("binary_sensor.")) {
      return true;
    }
    return false;
  }

  bool _activeDevicesShow = false;

  bool get activeDevicesShow => _activeDevicesShow;

  set activeDevicesShow(bool val) {
    if (val == null) {
      throw new ArgumentError();
    }
    if (_activeDevicesShow != val) {
      _activeDevicesShow = val;
      if (activeDevicesShow) activeDevicesOffTimer(60);
      notifyListeners();
    }
  }

  Timer _activeDevicesOffTimer;

  void activeDevicesOffTimer(int seconds) {
    _activeDevicesOffTimer?.cancel();
    _activeDevicesOffTimer = null;

    log.d("entitiesStatusShowTimer delay");

    _activeDevicesOffTimer =
        Timer(Duration(seconds: seconds), activeDevicesShowOff);
  }

  void activeDevicesShowOff() {
    gd.activeDevicesShow = false;
  }

  ScrollController viewNormalController = ScrollController();

  Color stringToColor(String colorString) {
//    String valueString =
//        colorString.split('(0x')[1].split(')')[0]; // kind of hacky..
    try {
      colorString = colorString.replaceAll("0x", "");
      colorString = colorString.replaceAll("0X", "");
      colorString = colorString.toUpperCase(); // kind of hacky..
      colorString = colorString.replaceAll("COLOR(", "");
      colorString = colorString.replaceAll(")", "");
      int value = int.parse(colorString, radix: 16);
      Color color = Color(value);
      return color;
    } catch (e) {
      log.d("stringToColor $colorString ");
      log.d("stringToColor $e");
      return Colors.grey;
    }
  }

  String colorToString(Color color) {
    String colorString = color.toString();
    colorString = colorString.toUpperCase();
    colorString = colorString.replaceAll("COLOR(0X", "");
    colorString = colorString.replaceAll(")", "");
    log.d("colorToString ${color.toString()} $colorString");
    return colorString;
  }

  List<String> webViewPresets = [
    "https://embed.windy.com",
    "https://www.yahoo.com/news/weather",
    "https://livescore.com",
  ];

  int webViewSupportMax = 3;

  String _currentLocale;

  String get currentLocale => _currentLocale;

  set currentLocale(String val) {
    if (val != null && val != "" && _currentLocale != val) {
      _currentLocale = val;
      setLocale();
    }
  }

  var localeData;

  List<bool> selectedLanguageIndex = [true, false, false];
  List<String> languageCode = ["en", "sv", "vi"];
  List<String> countryCode = ["US", "SE", "VN"];

  void setLocale() {
    log.d("setLocale ${gd.localeData.toString()} ");
    if (gd.currentLocale == "sv_SE") {
      gd.localeData.changeLocale(Locale("sv", "SE"));
      selectedLanguageIndex = [
        false,
        true,
        false,
      ];
    } else if (gd.currentLocale == "vi_VN") {
      gd.localeData.changeLocale(Locale("vi", "VN"));
      selectedLanguageIndex = [
        false,
        false,
        true,
      ];
    } else {
      gd.localeData.changeLocale(Locale("en", "US"));
      selectedLanguageIndex = [
        true,
        false,
        false,
      ];
    }
  }

  void httpApiStates() async {
    var client = new http.Client();
    var url = gd.currentUrl + "/api/states";
    Map<String, String> headers = {
      'content-type': 'application/json',
      'Authorization': 'Bearer ${gd.loginDataCurrent.longToken}',
    };

    log.d("httpApiStates $url");

    try {
      var response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        log.w("httpApiStates response.statusCode ${response.statusCode}");
        var jsonResponse = jsonDecode(response.body);
//        log.d("httpApiStates jsonResponse $jsonResponse");
        socketGetStates(jsonResponse);
      } else {
        print(
            "httpApiStates Request failed with status: ${response.statusCode}.");
      }
    } finally {
      client.close();
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hasskit/helper/LocaleHelper.dart';
import 'package:hasskit/helper/ThemeInfo.dart';
import 'package:hasskit/helper/WebSocket.dart';
import 'package:hasskit/view/PageViewBuilder.dart';
import 'package:hasskit/view/SettingPage.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider/provider.dart';
import 'helper/GeneralData.dart';
import 'helper/GoogleSign.dart';
import 'helper/Logger.dart';
import 'helper/MaterialDesignIcons.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart';

void main() {
//  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    EasyLocalization(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => GeneralData(),
            builder: (context) => GeneralData(),
          ),
        ],
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    gd = Provider.of<GeneralData>(context, listen: false);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    gd.localeData = EasyLocalizationProvider.of(context).data;

    return EasyLocalizationProvider(
      data: gd.localeData,
      child: Selector<GeneralData, ThemeData>(
        selector: (_, generalData) => generalData.currentTheme,
        builder: (_, currentTheme, __) {
          return MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              EasylocaLizationDelegate(
                  locale: gd.localeData.locale, path: 'assets/langs')
            ],
            locale: gd.localeData.savedLocale,
            supportedLocales: [
              Locale('en', 'US'),
              Locale('sv', 'SE'),
              Locale('vi', 'VN'),
            ],
            debugShowCheckedModeBanner: false,
            theme: currentTheme,
            title: 'HassKit',
            home: HomeView(),
          );
        },
      ),
    );
  }
}

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  bool showLoading = true;
  Timer timer0;
  Timer timer1;
  Timer timer10;
  Timer timer30;
  Timer timer5;
  Timer timer60;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(
      () {
        gd.lastLifecycleState = state;

        if (gd.lastLifecycleState == AppLifecycleState.resumed) {
          log.w("didChangeAppLifecycleState ${gd.lastLifecycleState}");

          gd.mediaQueryWidth = MediaQuery.of(context).size.width;
          log.w(
              "didChangeAppLifecycleState gd.mediaQueryWidth ${gd.mediaQueryWidth}");
          gd.mediaQueryHeight = MediaQuery.of(context).size.height;
          log.w(
              "didChangeAppLifecycleState gd.mediaQueryWidth ${gd.mediaQueryHeight}");
          if (gd.autoConnect) {
            {
              if (gd.connectionStatus != "Connected") {
                webSocket.initCommunication();
                log.w(
                    "didChangeAppLifecycleState webSocket.initCommunication()");
              } else {
                var outMsg = {"id": gd.socketId, "type": "get_states"};
                var outMsgEncoded = json.encode(outMsg);
                webSocket.send(outMsgEncoded);
                log.w(
                    "didChangeAppLifecycleState webSocket.send $outMsgEncoded");
              }
            }
          }
        }
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(_afterLayout);
    WidgetsBinding.instance.addObserver(this);
    googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        log.w("googleSignIn.onCurrentUserChanged");
        gd.googleSignInAccount = account;
      });
    });
    googleSignIn.signInSilently();

    timer0 = Timer.periodic(
        Duration(milliseconds: 200), (Timer t) => timer200Callback());
    timer1 =
        Timer.periodic(Duration(seconds: 1), (Timer t) => timer1Callback());
    timer5 =
        Timer.periodic(Duration(seconds: 5), (Timer t) => timer5Callback());
    timer10 =
        Timer.periodic(Duration(seconds: 10), (Timer t) => timer10Callback());
    timer30 =
        Timer.periodic(Duration(seconds: 30), (Timer t) => timer30Callback());
    timer60 =
        Timer.periodic(Duration(seconds: 60), (Timer t) => timer60Callback());

    mainInitState();
  }

  mainInitState() async {
    log.w("mainInitState showLoading $showLoading");
    log.w("mainInitState...");
    log.w("mainInitState START await loginDataInstance.loadLoginData");
    log.w("mainInitState...");
    log.w("mainInitState gd.loginDataListString");
    await Future.delayed(const Duration(milliseconds: 500));
    gd.loginDataListString = await gd.getString('loginDataList');
    await gd.getSettings("mainInitState");
  }

  timer200Callback() {}

  timer1Callback() {
    if (gd.mediaQueryHeight == 0) {
      gd.mediaQueryWidth = MediaQuery.of(context).size.width;
      log.w("build gd.mediaQueryWidth ${gd.mediaQueryWidth}");
      gd.mediaQueryHeight = MediaQuery.of(context).size.height;
      log.w("build gd.mediaQueryHeight ${gd.mediaQueryHeight}");
    }

    for (String entityId in gd.cameraInfosActive) {
      gd.cameraInfosUpdate(entityId);
    }
  }

  timer5Callback() {
    //in case websocket fail for no reason.
//    gd.httpApiStates();
  }

  timer10Callback() {
    if (gd.connectionStatus != "Connected" && gd.autoConnect) {
      webSocket.initCommunication();
    }
  }

  timer30Callback() {
    if (gd.connectionStatus == "Connected") {
      gd.delayGetStatesTimer(5);
//      use http
//      var outMsg = {"id": gd.socketId, "type": "get_states"};
//      var outMsgEncoded = json.encode(outMsg);
//      webSocket.send(outMsgEncoded);
    }
  }

  timer60Callback() {}

  _afterLayout(_) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    showLoading = false;
    log.w("showLoading $showLoading");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Selector<GeneralData, String>(
      selector: (_, generalData) =>
          "${generalData.viewMode} | " +
          "${Localizations.localeOf(context).languageCode} | " +
          "${generalData.baseSetting.itemsPerRow} | " +
          "${generalData.mediaQueryHeight} | " +
          "${generalData.connectionStatus} | " +
          "${generalData.roomList.length} | ",
      builder: (context, data, child) {
        return Scaffold(
          body: ModalProgressHUD(
            inAsyncCall: showLoading || gd.mediaQueryHeight == 0,
            opacity: 1,
            progressIndicator: SpinKitThreeBounce(
              size: 40,
              color: ThemeInfo.colorIconActive.withOpacity(0.5),
            ),
            color: ThemeInfo.colorBackgroundDark,
            child: CupertinoTabScaffold(
              tabBar: CupertinoTabBar(
                backgroundColor: ThemeInfo.colorBottomSheet.withOpacity(0.5),
                onTap: (int) {
                  log.d("CupertinoTabBar onTap $int");
                  gd.viewMode = ViewMode.normal;
                },
                currentIndex: 0,
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(MaterialDesignIcons.getIconDataFromIconName(
                        "mdi:home-automation")),
                    title: Text(
                      gd.getRoomName(0),
                      maxLines: 1,
                      textScaleFactor: gd.textScaleFactor,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: ThemeInfo.colorBottomSheetReverse),
                    ),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(MaterialDesignIcons.getIconDataFromIconName(
                        "mdi:view-carousel")),
                    title: Text(
//                  gd.getRoomName(gd.lastSelectedRoom + 1),
                      Translate.getString("global.rooms", context),
                      maxLines: 1,
                      textScaleFactor: gd.textScaleFactor,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: ThemeInfo.colorBottomSheetReverse),
                    ),
//                title: TestWidget(),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(MaterialDesignIcons.getIconDataFromIconName(
                        "mdi:settings")),
                    title: Text(
                      Translate.getString("global.settings", context),
                      maxLines: 1,
                      textScaleFactor: gd.textScaleFactor,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: ThemeInfo.colorBottomSheetReverse),
                    ),
                  ),
                ],
              ),
              tabBuilder: (context, index) {
                switch (index) {
                  case 0:
                    return CupertinoTabView(
                      builder: (context) {
                        return CupertinoPageScaffold(
                          child: SinglePage(roomIndex: 0),
//                          child: AnimationTemp(),
                        );
                      },
                    );
                  case 1:
                    return CupertinoTabView(
                      builder: (context) {
                        return CupertinoPageScaffold(
                          child: PageViewBuilder(),
                        );
                      },
                    );
                  case 2:
                    return CupertinoTabView(
                      builder: (context) {
                        return CupertinoPageScaffold(
                          child: SettingPage(),
                        );
                      },
                    );
                  default:
                    return CupertinoTabView(
                      builder: (context) {
                        return CupertinoPageScaffold(
                          child: SinglePage(roomIndex: 0),
                        );
                      },
                    );
                }
              },
            ),
          ),
        );
      },
    );
  }
}

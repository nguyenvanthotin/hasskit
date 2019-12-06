import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hasskit/helper/GeneralData.dart';
import 'package:hasskit/helper/GoogleSign.dart';
import 'package:hasskit/helper/Logger.dart';
import 'package:hasskit/helper/MaterialDesignIcons.dart';
import 'package:hasskit/helper/ThemeInfo.dart';
import 'package:hasskit/model/LoginData.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:validators/validators.dart';
import 'slivers/SliverHeader.dart';
import 'HomeAssistantLogin.dart';
import 'ServerSelectPanel.dart';
import 'package:hasskit/helper/LocaleHelper.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final _controller = TextEditingController();
  bool showConnect = false;
  bool showCancel = false;
  bool keyboardVisible = false;
  FocusNode addressFocusNode = new FocusNode();

  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );

  @override
  void dispose() {
    _controller.removeListener(addressListener);
    _controller.removeListener(addressFocusNodeListener);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    _controller.addListener(addressListener);
    _controller.addListener(addressFocusNodeListener);
  }

  addressFocusNodeListener() {
    if (addressFocusNode.hasFocus) {
      keyboardVisible = true;
      log.w(
          "addressFocusNode.hasFocus ${addressFocusNode.hasFocus} $keyboardVisible");
    } else {
      keyboardVisible = false;
      log.w(
          "addressFocusNode.hasFocus ${addressFocusNode.hasFocus} $keyboardVisible");
    }
  }

  addressListener() {
    if (isURL(_controller.text.trim(), protocols: ['http', 'https'])) {
//      log.d("validURL = true isURL ${addressController.text}");
      if (!showConnect) {
        showConnect = true;
        setState(() {});
      }
    } else {
//      log.d("validURL = false isURL ${addressController.text}");
      if (showConnect) {
        showConnect = false;
        setState(() {});
      }
    }

    if (_controller.text.trim().length > 0) {
      if (!showCancel) {
        showCancel = true;
        setState(() {});
      }
    } else {
      if (showCancel) {
        showCancel = false;
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // log.w("Widget build SettingPage");
    // if (gd.loginDataCurrent != null) {
    //   var pretext = gd.useSSL ? "https://" : "http://";
    //   log.w("Remove _controller.text ${_controller.text} "
    //       "url ${gd.loginDataCurrent.url} pretext $pretext");
    //   if (gd.loginDataCurrent.getUrl == pretext + _controller.text) {
    //     _controller.clear();
    //   }
    // }

//    return Consumer<GeneralData>(
//      builder: (context, gd, child) {
    return Selector<GeneralData, String>(
      selector: (_, generalData) => ("${generalData.useSSL} | "
          "${generalData.currentTheme} | "
          "${generalData.connectionStatus} | "
          "${generalData.baseSetting.itemsPerRow} | "
          "${generalData.loginDataList.length} | "),
      builder: (_, string, __) {
        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(gd.backgroundImage[10]),
              fit: BoxFit.cover,
            ),
//        gradient: LinearGradient(
//            begin: Alignment.topCenter,
//            end: Alignment.bottomCenter,
//            colors: [
//              Theme.of(context).primaryColorLight,
//              Theme.of(context).cardColor.withOpacity(0.2)
//            ]),
//        color: Theme.of(context).primaryColorLight,
          ),
          child: CustomScrollView(
            slivers: <Widget>[
              CupertinoSliverNavigationBar(
//                leading: Image(
//                  image: AssetImage(
//                      'assets/images/icon_transparent_border_transparent.png'),
//                ),
                backgroundColor: ThemeInfo.colorBottomSheet.withOpacity(0.5),
                largeTitle: Text(
                  Translate.getString("global.settings", context),
                  style: TextStyle(color: ThemeInfo.colorBottomSheetReverse),
                  textScaleFactor: gd.textScaleFactor,
                  overflow: TextOverflow.ellipsis,
                ),
//            trailing: IconButton(
//              icon: Icon(Icons.palette),
//              onPressed: () {
//                gd.themeChange();
//              },
//            ),
              ),
              SliverHeaderNormal(
                icon: Icon(
                  MaterialDesignIcons.getIconDataFromIconName(
                      "mdi:home-assistant"),
                ),
                title: Translate.getString("settings.home_assistant", context),
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TextFormField(
                            focusNode: addressFocusNode,
                            controller: _controller,
                            decoration: InputDecoration(
                              prefixText: gd.useSSL ? "https://" : "http://",
                              hintText: 'sample.duckdns.org:8123',
                              labelText: Translate.getString(
                                  "settings.new_connection", context),
                              suffixIcon: Opacity(
                                opacity: showCancel ? 1 : 0,
                                child: IconButton(
                                  icon: Icon(Icons.cancel),
                                  onPressed: () {
                                    _controller.clear();
                                    if (keyboardVisible) {
                                      FocusScope.of(context)
                                          .requestFocus(new FocusNode());
                                    }
                                  },
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.url,
                            autocorrect: false,
                            onEditingComplete: () {
                              FocusScope.of(context)
                                  .requestFocus(new FocusNode());
                            },
                          ),
                          Row(
                            children: <Widget>[
                              Switch.adaptive(
                                  activeColor: ThemeInfo.colorIconActive,
                                  value: gd.useSSL,
                                  onChanged: (val) {
                                    gd.useSSL = val;
                                  }),
                              Text(Translate.getString(
                                  "settings.use_https", context)),
                              Expanded(child: Container()),
                              RaisedButton(
                                onPressed: showConnect
                                    ? () {
                                        if (keyboardVisible) {
                                          FocusScope.of(context)
                                              .requestFocus(new FocusNode());
                                        }

                                        _controller.text =
                                            _controller.text.trim();
                                        _controller.text =
                                            _controller.text.toLowerCase();
                                        _controller.text = _controller.text
                                            .replaceAll("https://", "");
                                        _controller.text = _controller.text
                                            .replaceAll("http://", "");
                                        if (_controller.text.contains("/"))
                                          _controller.text =
                                              _controller.text.split("/")[0];

                                        gd.loginDataCurrent = LoginData(
                                            url: gd.useSSL
                                                ? "https://" + _controller.text
                                                : "http://" + _controller.text);
                                        log.w(
                                            "gd.loginDataCurrent.url ${gd.loginDataCurrent.url}");
                                        //prevent autoConnect hijack gd.loginDataCurrent.url
                                        gd.autoConnect = false;
                                        gd.webViewLoading = true;
                                        showModalBottomSheet(
                                          context: context,
                                          elevation: 1,
                                          backgroundColor:
                                              ThemeInfo.colorBottomSheet,
                                          isScrollControlled: true,
                                          useRootNavigator: true,
                                          builder: (context) =>
                                              HomeAssistantLogin(
                                            selectedUrl: gd
                                                    .loginDataCurrent.getUrl +
                                                '/auth/authorize?client_id=' +
                                                gd.loginDataCurrent.getUrl +
                                                "/hasskit"
                                                    '&redirect_uri=' +
                                                gd.loginDataCurrent.getUrl +
                                                "/hasskit",
                                          ),
                                        );
                                      }
                                    : null,
                                child: Text(Translate.getString(
                                    "settings.connect", context)),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      ServerSelectPanel(gd.loginDataList[index]),
                  childCount: gd.loginDataList.length,
                ),
              ),
              SliverHeaderNormal(
                icon: Icon(
                  MaterialDesignIcons.getIconDataFromIconName("mdi:cloud-sync"),
                ),
                title: Translate.getString("settings.sync", context),
              ),
              GoogleSign(),
              SliverHeaderNormal(
                icon: Icon(
                  MaterialDesignIcons.getIconDataFromIconName("mdi:palette"),
                ),
                title: Translate.getString("settings.theme_color", context),
              ),
              _ThemeSelector(),
              SliverHeaderNormal(
                icon: Icon(
                  MaterialDesignIcons.getIconDataFromIconName(
                      "mdi:view-dashboard-variant"),
                ),
                title: Translate.getString("settings.layout", context),
              ),
              _LayoutSelector(),
              SliverHeaderNormal(
                icon: Icon(
                  MaterialDesignIcons.getIconDataFromIconName("mdi:web"),
                ),
                title: Translate.getString("settings.language", context),
              ),
              _LanguageSelector(),
              SliverHeaderNormal(
                icon: Icon(
                  MaterialDesignIcons.getIconDataFromIconName(
                      "mdi:account-circle"),
                ),
                title: Translate.getString("settings.about", context),
              ),
              Container(
                child: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Container(
                        padding: EdgeInsets.all(8),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color:
                                  ThemeInfo.colorBottomSheet.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            Translate.getString("settings.about_info", context),
                            style: Theme.of(context).textTheme.body1,
                            textAlign: TextAlign.justify,
                            textScaleFactor: gd.textScaleFactor,
                          ),
                        ),
                      ),
                      Container(
                        color: Colors.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            SizedBox(width: 10),
                            Expanded(
                              child: RaisedButton(
                                onPressed: _launchDiscord,
                                child: Row(
                                  children: <Widget>[
                                    SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: Image(
                                        image: AssetImage(
                                            'assets/images/discord-512.png'),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Discord ",
                                      style: TextStyle(color: Colors.black),
                                      textScaleFactor: gd.textScaleFactor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: RaisedButton(
                                onPressed: _launchFacebook,
                                child: Row(
                                  children: <Widget>[
                                    SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: Image(
                                        image: AssetImage(
                                            'assets/images/facebook-logo.png'),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Facebook",
                                      style: TextStyle(color: Colors.black),
                                      textScaleFactor: gd.textScaleFactor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(8),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color:
                                  ThemeInfo.colorBottomSheet.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(
//                        "App Name: ${_packageInfo.appName} - "
//                      "Package: ${_packageInfo.packageName}\n"
                            "Version: ${_packageInfo.version} - "
                            "Build: ${_packageInfo.buildNumber}",
                            style: Theme.of(context).textTheme.body1,
                            textAlign: TextAlign.center,
                            textScaleFactor: gd.textScaleFactor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverSafeArea(
                sliver: gd.emptySliver,
              )
            ],
          ),
        );
      },
    );
  }

  _launchDiscord() async {
    const url = 'https://discord.gg/cqYr52P';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  _launchFacebook() async {
    const fbProtocolUrl = "fb://group/709634206223205";
    const fallbackUrl = 'https://www.facebook.com/groups/709634206223205/';
    try {
      bool launched = await launch(fbProtocolUrl, forceSafariVC: false);

      if (!launched) {
        await launch(fallbackUrl, forceSafariVC: false);
      }
    } catch (e) {
      await launch(fallbackUrl, forceSafariVC: false);
    }

//    const url = 'https://www.facebook.com/groups/709634206223205/';
//
//    if (await canLaunch(url)) {
//      await launch(url);
//    } else {
//      throw 'Could not launch $url';
//    }
  }

  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      log.d("_packageInfo $_packageInfo");
      _packageInfo = info;
    });
  }
}

class _ThemeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverFixedExtentList(
      itemExtent: 58,
      delegate: SliverChildListDelegate(
        [
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: InkWell(
                    onTap: () {
                      gd.baseSetting.themeIndex = 1;
                      gd.baseSettingSave(true);
                    },
                    child: Card(
                      elevation: 1,
                      color: Color.fromRGBO(28, 28, 28, 1).withOpacity(0.5),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: <Widget>[
                            Image.asset("assets/images/icon_transparent.png"),
                            Spacer(),
                            Text(
                              Translate.getString(
                                  "theme_selector.dark", context),
                              style: TextStyle(color: Colors.white),
                              textScaleFactor: gd.textScaleFactor,
                            ),
                            Spacer(),
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.amber
                                  : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      gd.baseSetting.themeIndex = 0;
                      gd.baseSettingSave(true);
                    },
                    child: Card(
                      elevation: 1,
                      color: Color.fromRGBO(255, 255, 255, 1).withOpacity(0.5),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: <Widget>[
                            Image.asset("assets/images/icon_transparent.png"),
                            Spacer(),
                            Text(
                              Translate.getString(
                                  "theme_selector.light", context),
                              style: TextStyle(color: Colors.black),
                              textScaleFactor: gd.textScaleFactor,
                            ),
                            Spacer(),
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.amber
                                  : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LayoutSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverFixedExtentList(
      itemExtent: 58,
      delegate: SliverChildListDelegate(
        [
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: InkWell(
                    onTap: () {
                      gd.baseSetting.itemsPerRow = 3;
                      gd.baseSettingSave(true);
                    },
                    child: Card(
                      elevation: 1,
                      color: ThemeInfo.colorBottomSheet.withOpacity(0.8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              MaterialDesignIcons.getIconDataFromIconName(
                                  "mdi:view-module"),
                              size: 32,
                            ),
                            Spacer(),
                            Text(
                              Translate.getString(
                                  "settings.3_buttons", context),
                              style: Theme.of(context).textTheme.body1,
                              overflow: TextOverflow.ellipsis,
                              textScaleFactor: gd.textScaleFactor,
                            ),
                            Spacer(),
                            Icon(
                              Icons.check_circle,
                              color: gd.baseSetting.itemsPerRow == 3
                                  ? Colors.amber
                                  : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      gd.baseSetting.itemsPerRow = 4;
                      gd.baseSettingSave(true);
                    },
                    child: Card(
                      elevation: 1,
                      color: ThemeInfo.colorBottomSheet.withOpacity(0.8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              MaterialDesignIcons.getIconDataFromIconName(
                                  "mdi:view-comfy"),
                              size: 32,
                            ),
                            Spacer(),
                            Text(
                              Translate.getString(
                                  "settings.4_buttons", context),
                              style: Theme.of(context).textTheme.body1,
                              overflow: TextOverflow.ellipsis,
                              textScaleFactor: gd.textScaleFactor,
                            ),
                            Spacer(),
                            Icon(
                              Icons.check_circle,
                              color: gd.baseSetting.itemsPerRow == 4
                                  ? Colors.amber
                                  : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate(
        [
          Container(
            alignment: Alignment.center,
            child: ToggleButtons(
              isSelected: gd.selectedLanguageIndex,
              constraints: BoxConstraints.tight(Size(42, 32)),
              borderColor: Colors.transparent,
              selectedBorderColor: Colors.transparent,
              children: <Widget>[
                Image.asset(
                  "assets/flags/gb.png",
                  fit: BoxFit.cover,
                  width: 40,
                  height: 30,
                ),
                Image.asset(
                  "assets/flags/se.png",
                  fit: BoxFit.cover,
                  width: 40,
                  height: 30,
                ),
                Image.asset(
                  "assets/flags/vn.png",
                  fit: BoxFit.cover,
                  width: 40,
                  height: 30,
                ),
              ],
              onPressed: (int index) {
                for (int buttonIndex = 0;
                    buttonIndex < gd.selectedLanguageIndex.length;
                    buttonIndex++) {
                  if (buttonIndex == index) {
                    log.d(
                        "buttonIndex $buttonIndex gd.languageCode[buttonIndex] ${gd.languageCode[buttonIndex]} gd.countryCode[buttonIndex] ${gd.countryCode[buttonIndex]}");

                    gd.selectedLanguageIndex[buttonIndex] = true;
                    gd.localeData.changeLocale(Locale(
                      gd.languageCode[buttonIndex],
                      gd.countryCode[buttonIndex],
                    ));
                  } else {
                    gd.selectedLanguageIndex[buttonIndex] = false;
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

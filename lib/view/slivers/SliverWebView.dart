import 'dart:async';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hasskit/helper/GeneralData.dart';
import 'package:hasskit/helper/Logger.dart';
import 'package:hasskit/helper/MaterialDesignIcons.dart';
import 'package:hasskit/helper/ThemeInfo.dart';
import 'package:flutter/gestures.dart';
import 'package:hasskit/helper/LocaleHelper.dart';

class SliverWebView extends StatelessWidget {
  final String webViewsId;
  const SliverWebView({@required this.webViewsId});
  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return WebView(
            webViewsId: webViewsId,
          );
        },
        addAutomaticKeepAlives: false,
        childCount: 1,
      ),
    );
  }
}

class WebView extends StatefulWidget {
  final String webViewsId;

  const WebView({@required this.webViewsId});

  @override
  _WebViewState createState() => _WebViewState();
}

class _WebViewState extends State<WebView> {
  final TextEditingController textController = TextEditingController();
  final Set<Factory> gestureRecognizers = [
    Factory(() => EagerGestureRecognizer()),
  ].toSet();

  InAppWebViewController webController;
  String currentUrl = "https://google.com";
  double ratio = 0.7;
  double ratioDisplay = 0.7;
  double opacity = 0.2;
  bool showSpin = true;
  bool showAddress = false;
  bool pinWebView = true;

  @override
  void initState() {
    super.initState();
    currentUrl = gd.baseSetting.getWebViewUrl(widget.webViewsId);
    if (currentUrl == null) currentUrl = "https://embed.windy.com";
    ratio = gd.baseSetting.getWebViewRatio(widget.webViewsId);
    if (ratio == null) ratio = 0.7;
    ratioDisplay = ratio;
    textController.text = currentUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      height: ratio * gd.mediaQueryWidth,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: ThemeInfo.colorBackgroundDark.withOpacity(0.5),
              blurRadius: 1.0, // has the effect of softening the shadow
              spreadRadius: 1.0, // has the effect of extending the shadow
              offset: Offset(
                0.0, // horizontal, move right 10
                1.0, // vertical, move down 10
              ),
            ),
          ],
        ),
        padding: EdgeInsets.all(2),

//      child: ClipRRect(
//        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.topLeft,
          children: <Widget>[
            buildInAppWebView(),
            showSpin
                ? Container(
                    decoration: BoxDecoration(
//                    borderRadius: BorderRadius.circular(12),
                      color: ThemeInfo.colorBackgroundDark.withOpacity(1),
                    ),
                    child: SpinKitThreeBounce(
                      size: 40,
                      color: ThemeInfo.colorIconActive.withOpacity(0.5),
                    ),
                  )
                : Container(),
            Column(
              children: <Widget>[
                Opacity(
                  opacity: showAddress ? 1 : opacity,
                  child: Container(
                    decoration: BoxDecoration(
                      color: showAddress
                          ? ThemeInfo.colorBottomSheet
                          : Colors.transparent,
//                  borderRadius: BorderRadius.only(
//                    topLeft: Radius.circular(12),
//                    topRight: Radius.circular(12),
//                  ),
                    ),
                    padding: EdgeInsets.all(8),
                    child: Row(
                      children: <Widget>[
                        webButton(context),
                        reloadButton(context),
                        pintButton(context),
                        Spacer(),
                        presetButtons(),
                      ],
                    ),
                  ),
                ),
                addressAndAspect(),
              ],
            ),
          ],
        ),
//      ),
      ),
    );
  }

  //FUCK WebView/InAppWebView with parent ClipRRect will crash in iOS, take 1 day to figure out.
  Widget buildInAppWebView() {
//    print("buildInAppWebView currentUrl $currentUrl");
    return Container(
      child: InAppWebView(
        initialUrl: currentUrl,
        gestureRecognizers: pinWebView ? null : gestureRecognizers,
        initialHeaders: {},
        initialOptions: InAppWebViewWidgetOptions(
            inAppWebViewOptions: InAppWebViewOptions(
          debuggingEnabled: true,
        )),
        onWebViewCreated: (InAppWebViewController controller) {
          print("onWebViewCreated currentUrl $currentUrl");
          webController = controller;
        },
        onLoadStart: (InAppWebViewController controller, String url) {
          setState(() {
            print("onLoadStart url $url");
            showSpin = true;
          });
        },
        onLoadStop: (InAppWebViewController controller, String url) async {
          setState(() {
            print("onLoadStop url $url");
            showSpin = false;
          });
        },
        onProgressChanged: (InAppWebViewController controller, int progress) {
          setState(() {
            if (progress > 90) showSpin = false;
//            log.d("onProgressChanged progress $progress");
          });
        },
      ),
    );
  }

  Widget presetButtons() {
    return showAddress
        ? Row(
            children: <Widget>[
              InkWell(
                onTap: () {
                  setState(() {
                    textController.text = gd.webViewPresets[0];
                    changeUrl(textController.text);
                    showAddress = false;
                  });
                },
                child: Container(
                  child: Text(
                    Translate.getString("webview.windy", context),
                    textScaleFactor: gd.textScaleFactor,
                  ),
                ),
              ),
              Container(child: Text(" | ")),
              InkWell(
                onTap: () {
                  setState(() {
                    textController.text = gd.webViewPresets[1];
                    changeUrl(textController.text);
                    showAddress = false;
                  });
                },
                child: Container(
                  child: Text(
                    Translate.getString("webview.y_weather", context),
                    textScaleFactor: gd.textScaleFactor,
                  ),
                ),
              ),
              Container(child: Text(" | ")),
              InkWell(
                onTap: () {
                  setState(() {
                    textController.text = gd.webViewPresets[2];
                    changeUrl(textController.text);
                    showAddress = false;
                  });
                },
                child: Text(
                  Translate.getString("webview.live_score", context),
                  textScaleFactor: gd.textScaleFactor,
                ),
              ),
            ],
          )
        : Container();
  }

  changeUrl(String url) {
    log.d("changeUrl $url");
    setState(() {
      currentUrl = url;
      webController.loadUrl(url: currentUrl);
      showSpin = true;

      if (widget.webViewsId == "WebView1") {
        gd.baseSetting.webView1Url = url;
        gd.baseSettingSave(true);
      }
      if (widget.webViewsId == "WebView2") {
        gd.baseSetting.webView2Url = url;
        gd.baseSettingSave(true);
      }
      if (widget.webViewsId == "WebView3") {
        gd.baseSetting.webView3Url = url;
        gd.baseSettingSave(true);
      }
    });
  }

  Widget addressAndAspect() {
    return showAddress
        ? Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: ThemeInfo.colorBottomSheet.withOpacity(1),
//                borderRadius: BorderRadius.only(
//                  bottomLeft: Radius.circular(12),
//                  bottomRight: Radius.circular(12),
//                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: "https://www.siteadress.com",
                    ),
                    controller: textController,
                    autocorrect: false,
                    autovalidate: true,
                    autofocus: true,
                    maxLines: 3,
                    onChanged: (val) {
                      changeOpacity();
                    },
                    onEditingComplete: () {
                      changeUrl(textController.text);
                    },
                  ),
                  Row(
                    children: <Widget>[
                      Text(Translate.getString("webview.aspect", context)),
                      SizedBox(width: 8),
                      Icon(MaterialDesignIcons.getIconDataFromIconName(
                          "mdi:crop-landscape")),
                      Expanded(
                        child: Slider(
                          label: "${ratioDisplay.toStringAsFixed(1)}",
                          divisions: 10,
                          min: 0.5,
                          value: ratioDisplay,
                          max: 1.5,
                          onChanged: (val) {
                            setState(() {
                              ratioDisplay = val;
                            });
                          },
                          onChangeEnd: (val) {
                            setState(() {
                              ratio = val;
                              ratioDisplay = val;
                              changeAspect(val);
                            });
                          },
                        ),
                      ),
                      Icon(MaterialDesignIcons.getIconDataFromIconName(
                          "mdi:crop-portrait")),
                    ],
                  ),
                ],
              ),
            ),
          )
        : Container();
  }

  Timer _changeAspectTimer;

  void changeAspect(double val) {
    _changeAspectTimer?.cancel();
    _changeAspectTimer = null;
    _changeAspectTimer = Timer(Duration(seconds: 1), () {
      setState(() {
        ratio = val;

        if (widget.webViewsId == "WebView1") {
          gd.baseSetting.webView1Ratio = val;
          gd.baseSettingSave(true);
        }
        if (widget.webViewsId == "WebView2") {
          gd.baseSetting.webView2Ratio = val;
          gd.baseSettingSave(true);
        }
        if (widget.webViewsId == "WebView3") {
          gd.baseSetting.webView3Ratio = val;
          gd.baseSettingSave(true);
        }
      });
    });
  }

  Widget webButton(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          changeOpacity();
          if (showAddress) changeUrl(textController.text.trim());
          showAddress = !showAddress;
          Flushbar(
            message: showAddress
                ? Translate.getString("webview.edit", context)
                : Translate.getString("webview.saved", context),
            duration: Duration(seconds: 3),
            shouldIconPulse: true,
            icon: Icon(
              Icons.info,
              color: ThemeInfo.colorIconActive,
            ),
          )..show(context);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: ThemeInfo.colorBottomSheet.withOpacity(0.5),
              offset: new Offset(0.0, 0.0),
              blurRadius: 1.0,
            )
          ],
        ),
        child: showAddress
            ? Icon(
                MaterialDesignIcons.getIconDataFromIconName("mdi:content-save"))
            : Icon(MaterialDesignIcons.getIconDataFromIconName("mdi:pencil")),
      ),
    );
  }

  Widget reloadButton(BuildContext context) {
    return !showAddress
        ? InkWell(
            onTap: () {
              changeOpacity();
              webController.reload();
              Flushbar(
                message: Translate.getString("webview.reload", context),
                duration: Duration(seconds: 3),
                shouldIconPulse: true,
                icon: Icon(
                  Icons.info,
                  color: ThemeInfo.colorIconActive,
                ),
              )..show(context);
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ThemeInfo.colorBottomSheet.withOpacity(0.5),
                    offset: new Offset(0.0, 0.0),
                    blurRadius: 1.0,
                  )
                ],
              ),
              child: Icon(
                  MaterialDesignIcons.getIconDataFromIconName("mdi:refresh")),
            ),
          )
        : Container();
  }

  Widget pintButton(BuildContext context) {
    return !showAddress
        ? InkWell(
            onTap: () {
              setState(() {
                changeOpacity();
                pinWebView = !pinWebView;
                Flushbar(
                  message: pinWebView
                      ? Translate.getString("webview.pin", context)
                      : Translate.getString("webview.unpin", context),
                  duration: Duration(seconds: 3),
                  shouldIconPulse: true,
                  icon: Icon(
                    Icons.info,
                    color: ThemeInfo.colorIconActive,
                  ),
                )..show(context);
              });
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ThemeInfo.colorBottomSheet.withOpacity(0.5),
                    offset: new Offset(0.0, 0.0),
                    blurRadius: 1.0,
                  )
                ],
              ),
              child: pinWebView
                  ? Icon(MaterialDesignIcons.getIconDataFromIconName("mdi:pin"))
                  : Icon(MaterialDesignIcons.getIconDataFromIconName(
                      "mdi:pin-off")),
            ),
          )
        : Container();
  }

  Timer _changeOpacityTimer;

  void changeOpacity() {
    opacity = 1;
    _changeOpacityTimer?.cancel();
    _changeOpacityTimer = null;
    _changeOpacityTimer = Timer(Duration(seconds: 10), () {
      setState(() {
        opacity = 0.2;
      });
    });
  }
}

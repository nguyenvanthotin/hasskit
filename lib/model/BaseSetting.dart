import 'package:flutter/material.dart';

const List<String> baseSettingDefaultColor = [
  "0xffEEEEEE",
  "0xffEF5350",
  "0xffFFCA28",
  "0xff66BB6A",
  "0xff42A5F5",
  "0xffAB47BC",
//  Color(0xffEEEEEE), //EEEEEE Gray
//  Color(0xffEF5350), //EF5350 Red
//  Color(0xffFFCA28), //FFCA28 Amber
//  Color(0xff66BB6A), //66BB6A Green
////    Color(0xff26C6DA), //26C6DA Cyan
//  Color(0xff42A5F5), //42A5F5 Blue
//  Color(0xffAB47BC), //AB47BC Purple
];

class BaseSetting {
  int itemsPerRow;
  int themeIndex;
  String lastArmType;
  List<String> notificationDevices;
  List<String> colorPicker;
  double webView1Ratio = 0.7;
  String webView1Url = "https://embed.windy.com";
  double webView2Ratio = 1.0;
  String webView2Url = "https://www.yahoo.com/news/weather";
  double webView3Ratio = 1.2;
  String webView3Url = "https://livescore.com";

  BaseSetting({
    @required this.itemsPerRow,
    @required this.themeIndex,
    @required this.lastArmType,
    @required this.notificationDevices,
    @required this.colorPicker,
    this.webView1Ratio,
    this.webView1Url,
    this.webView2Ratio,
    this.webView2Url,
    this.webView3Ratio,
    this.webView3Url,
  });

  Map<String, dynamic> toJson() => {
        'itemsPerRow': itemsPerRow,
        'themeIndex': themeIndex,
        'lastArmType': lastArmType,
        'notificationDevices': notificationDevices,
        'colorPicker': colorPicker,
        'webView1Ratio': webView1Ratio,
        'webView1Url': webView1Url,
        'webView2Ratio': webView2Ratio,
        'webView2Url': webView2Url,
        'webView3Ratio': webView3Ratio,
        'webView3Url': webView3Url,
      };

  factory BaseSetting.fromJson(Map<String, dynamic> json) {
    return BaseSetting(
      itemsPerRow: json['itemsPerRow'] != null ? json['itemsPerRow'] : 3,
      themeIndex: json['themeIndex'] != null ? json['themeIndex'] : 1,
      lastArmType:
          json['lastArmType'] != null ? json['lastArmType'] : "arm_away",
      notificationDevices: json['notificationDevices'] != null
          ? List<String>.from(json['notificationDevices'])
          : [],
      colorPicker: json['colorPicker'] != null
          ? List<String>.from(json['colorPicker'])
          : [
              "0xffEEEEEE",
              "0xffEF5350",
              "0xffFFCA28",
              "0xff66BB6A",
              "0xff42A5F5",
              "0xffAB47BC",
            ],
      webView1Ratio:
          json['webView1Ratio'] != null ? json['webView1Ratio'] : 0.7,
      webView1Url: json['webView1Url'] != null
          ? json['webView1Url']
          : "https://embed.windy.com",
      webView2Ratio:
          json['webView2Ratio'] != null ? json['webView2Ratio'] : 1.0,
      webView2Url: json['webView2Url'] != null
          ? json['webView2Url']
          : "https://www.yahoo.com/news/weather",
      webView3Ratio:
          json['webView3Ratio'] != null ? json['webView3Ratio'] : 1.2,
      webView3Url: json['webView3Url'] != null
          ? json['webView3Url']
          : "https://livescore.com",
    );
  }

  double getWebViewRatio(String webViewId) {
    switch (webViewId) {
      case "WebView1":
        return webView1Ratio;
      case "WebView2":
        return webView2Ratio;
      case "WebView3":
        return webView3Ratio;
      default:
        return webView1Ratio;
    }
  }

  String getWebViewUrl(String webViewId) {
    print("getWebViewUrl $webViewId");
    switch (webViewId) {
      case "WebView1":
        return webView1Url;
      case "WebView2":
        return webView2Url;
      case "WebView3":
        return webView3Url;
      default:
        return webView1Url;
    }
  }
}

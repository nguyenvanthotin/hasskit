import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hasskit/helper/GeneralData.dart';
import 'package:hasskit/helper/Logger.dart';
import 'package:hasskit/helper/ThemeInfo.dart';

class LocalLanguage {
  String languageCode;
  String countryCode;
  String displayName;
  String translator;

  LocalLanguage({
    @required this.languageCode,
    @required this.countryCode,
    @required this.displayName,
    @required this.translator,
  });
}

class LocalLanguagePicker extends StatefulWidget {
  @override
  _LocalLanguagePickerState createState() => _LocalLanguagePickerState();
}

class _LocalLanguagePickerState extends State<LocalLanguagePicker> {
  List<LocalLanguage> localLanguages = [
    LocalLanguage(
      languageCode: "en",
      countryCode: "US",
      displayName: "English",
      translator: "tuanha2000vn",
    ),
    LocalLanguage(
      languageCode: "sv",
      countryCode: "SE",
      displayName: "Svenka",
      translator: "Tyre88",
    ),
    LocalLanguage(
      languageCode: "vi",
      countryCode: "VN",
      displayName: "Tiếng Việt",
      translator: "tuanha2000vn",
    ),
    LocalLanguage(
      languageCode: "bg",
      countryCode: "BG",
      displayName: "България",
      translator: "kirichkov",
    ),
    LocalLanguage(
      languageCode: "el",
      countryCode: "GR",
      displayName: "ελληνικά",
      translator: "smartHomeHub",
    ),
    LocalLanguage(
      languageCode: "zh",
      countryCode: "TW",
      displayName: "中文",
      translator: "bluefoxlee",
    ),
  ];

  String languageCode;
  String countryCode;
  @override
  void initState() {
    super.initState();
    log.d("_LocalLanguagePickerState ${gd.localeData.savedLocale}");
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pickerWidgets = [];

    localLanguages.sort((a, b) =>
        (a.languageCode.toString() + "-" + a.languageCode.toString()).compareTo(
            b.languageCode.toString() + "-" + b.languageCode.toString()));

    int selectedIndex = 0;
    int i = 0;

    for (var localLanguage in localLanguages) {
      log.d(
          "${gd.localeData.savedLocale} i = $i ${localLanguage.languageCode}_${localLanguage.countryCode}");
      if (gd.localeData.savedLocale != null &&
          gd.localeData.savedLocale.toString() ==
              "${localLanguage.languageCode}_${localLanguage.countryCode}") {
        selectedIndex = i;
        log.d("selectedIndex $selectedIndex");
      }
      i++;
      var pickerWidget = Row(
        children: <Widget>[
//          SizedBox(width: 4),
          SizedBox(width: 30),
          SizedBox(
            width: 20,
            height: 15,
            child: Image.asset(
              "assets/flags/${localLanguage.countryCode.toLowerCase()}.png",
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 10),
//          SizedBox(
//            width: 50,
//            child: Text(
//              "${localLanguage.languageCode}-${localLanguage.countryCode}",
//              style: Theme.of(context).textTheme.body1,
//              textScaleFactor: gd.textScaleFactor,
//              overflow: TextOverflow.ellipsis,
//            ),
//          ),
          Expanded(
            child: Text(
              "${localLanguage.displayName} - ©${gd.textToDisplay(localLanguage.translator)} (${localLanguage.languageCode}-${localLanguage.countryCode})",
              style: Theme.of(context).textTheme.body1,
              textScaleFactor: gd.textScaleFactor,
              overflow: TextOverflow.ellipsis,
            ),
          ),
//          SizedBox(width: 8),
//          Text(
//            "by ${gd.textToDisplay(localLanguage.creditor)}",
//            style: Theme.of(context).textTheme.body1,
//            textScaleFactor: gd.textScaleFactor,
//            overflow: TextOverflow.ellipsis,
//          ),
        ],
      );
      pickerWidgets.add(pickerWidget);
    }
    FixedExtentScrollController _scrollController =
        FixedExtentScrollController(initialItem: selectedIndex);

    return SliverList(
      delegate: SliverChildListDelegate(
        [
          Container(
            padding: EdgeInsets.all(4),
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
//                color: ThemeInfo.colorBottomSheet.withOpacity(0.5),
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ThemeInfo.colorBackgroundDark.withOpacity(0.5),
                      ThemeInfo.colorBackgroundDark.withOpacity(0.0),
                      ThemeInfo.colorBackgroundDark.withOpacity(0.5),
                    ]),
                borderRadius: BorderRadius.circular(8)),
            height: 150,
            child: CupertinoPicker(
              diameterRatio: 1000,
              scrollController: _scrollController,
              magnification: 0.8,
//              backgroundColor: ThemeInfo.colorBackgroundDark.withOpacity(0.8),
              backgroundColor: Colors.transparent,
              children: pickerWidgets,
              itemExtent: 40,
              //height of each item
              looping: true,
              onSelectedItemChanged: (int index) {
                setState(() {
                  languageCode = localLanguages[index].languageCode;
                  countryCode = localLanguages[index].countryCode;
                  delaySwitchLanguageTimer(2);
                });
              },
            ),
          )
        ],
      ),
    );
  }

  Timer _delaySwitchLanguage;

  void delaySwitchLanguageTimer(int seconds) {
    _delaySwitchLanguage?.cancel();
    _delaySwitchLanguage = null;

    _delaySwitchLanguage =
        Timer(Duration(seconds: seconds), delaySwitchLanguage);
  }

  void delaySwitchLanguage() {
    gd.localeData.changeLocale(
      Locale(
        languageCode,
        countryCode,
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';

class Translate {
  static String getString(
    String key,
    BuildContext context,
  ) {
    if (AppLocalizations.of(context) != null) {
      var t = AppLocalizations.of(context);
      String val = t.tr(key);
      return val;
    } else {
      return "e:" + key;
    }
  }
}

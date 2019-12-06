import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hasskit/helper/GeneralData.dart';
import 'package:hasskit/helper/Logger.dart';
import 'package:hasskit/helper/ThemeInfo.dart';
import 'package:hasskit/model/Sensor.dart';
import 'package:hasskit/helper/SensorChart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:hasskit/helper/LocaleHelper.dart';

class EntityControlSensor extends StatefulWidget {
  final String entityId;

  const EntityControlSensor({@required this.entityId});

  @override
  _EntityControlSensorState createState() => _EntityControlSensorState();
}

class _EntityControlSensorState extends State<EntityControlSensor> {
  String batteryLevel;
  String deviceClass;
  bool inAsyncCall = true;
  double stateMin;
  double stateMax;
  List<FlSpot> flSpots = [];
  @override
  void initState() {
    super.initState();
    getHistory();
  }

  @override
  Widget build(BuildContext context) {
    Widget displayWidget;
    if (inAsyncCall)
      displayWidget = Container();
    else if (gd.sensors.length < 1)
      displayWidget = Container(
        child: Center(
          child: Text(
              "${gd.textToDisplay(gd.entities[widget.entityId].getOverrideName)} ${Translate.getString('global.no_data', context)} ${gd.sensors.length}"),
        ),
      );
    else if (gd.sensors.length < 4) {
      displayWidget = SensorLowNumber();
    } else {
      displayWidget = SensorChart(
        stateMin: stateMin,
        stateMax: stateMax,
        flSpots: flSpots,
      );
    }
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
      height: gd.mediaQueryHeight - kBottomNavigationBarHeight - kToolbarHeight,
      width: gd.mediaQueryWidth,
      child: ModalProgressHUD(
        inAsyncCall: inAsyncCall,
        opacity: 0,
        progressIndicator: SpinKitThreeBounce(
          size: 40,
          color: ThemeInfo.colorIconActive.withOpacity(0.5),
        ),
        child: Container(
          height: gd.mediaQueryWidth * 5 / 8,
          child: displayWidget,
        ),
      ),
    );
  }

  void getHistory() async {
    var continueBreak = 0;
    var client = new http.Client();
    var url = gd.currentUrl +
        "/api/history/period?filter_entity_id=${widget.entityId}";
    Map<String, String> headers = {
      'content-type': 'application/json',
      'Authorization': 'Bearer ${gd.loginDataCurrent.longToken}',
    };

    log.d("url $url");

    try {
      var response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
//        log.w("response.statusCode ${response.statusCode}");
        var jsonResponse = jsonDecode(response.body);
        log.d("getHistory jsonResponse $jsonResponse");
        gd.sensors = [];
        for (var rec in jsonResponse[0]) {
          if (continueBreak > 5) {
            break;
          }
          var sensor = Sensor.fromJson(rec);

          var lastUpdated = DateTime.tryParse(sensor.lastUpdated);
          if (lastUpdated == null) {
            continueBreak++;
            continue;
          }
          var lastChanged = DateTime.tryParse(sensor.lastChanged);
          if (lastChanged == null) {
            continueBreak++;
            continue;
          }
          var state = double.tryParse(sensor.state);
          if (state == null) {
            continueBreak++;
            continue;
          }

          gd.sensors.add(sensor);

          if (stateMin == null) stateMin = state;
          if (stateMax == null) stateMax = state;
          if (state > stateMax) stateMax = state;
          if (state < stateMin) stateMin = state;
        }

        log.d("gd.sensors.length ${gd.sensors.length}");

        if (jsonResponse[0] != null && jsonResponse[0][0] != null) {
          batteryLevel =
              (jsonResponse[0][0]["attributes"]["battery_level"]).toString();
          deviceClass =
              (jsonResponse[0][0]["attributes"]["device_class"]).toString();
          log.d(
              "gd.sensors.length ${gd.sensors.length} batteryLevel $batteryLevel deviceClass $deviceClass");
        }
        gd.sensors.sort((a, b) => DateTime.parse(a.lastUpdated)
            .toLocal()
            .compareTo(DateTime.parse(b.lastUpdated).toLocal()));

        processTable();

        if (stateMin != null && stateMax != null) {
          var range = (stateMax - stateMin).abs();
          var borderNumber;
          range == 0 ? borderNumber = 1 : borderNumber = range * 0.1;
          stateMin = stateMin - borderNumber;
          stateMax = stateMax + borderNumber;
          log.d(
              "stateMin $stateMin stateMax $stateMax borderNumber $borderNumber");
        }

        setState(() {
          inAsyncCall = false;
        });
      } else {
        setState(() {
          inAsyncCall = false;
        });
        print("Request failed with status: ${response.statusCode}.");
      }
    } finally {
      setState(() {
        inAsyncCall = false;
      });
      client.close();
    }
  }

  void processTable() {
    var now = DateTime.now().toLocal().millisecondsSinceEpoch.toDouble();
    var now24 = DateTime.now()
        .toLocal()
        .subtract(Duration(hours: 24))
        .millisecondsSinceEpoch
        .toDouble();
    log.d("processTable");

    trimData();

    for (int i = 0; i < gd.sensors.length; i++) {
      var lastChanged = DateTime.tryParse(gd.sensors[i].lastUpdated)
          .toUtc()
          .millisecondsSinceEpoch
          .toDouble();
      if (lastChanged == null) {
        log.e("Can't parse lastChanged ${gd.sensors[i].lastUpdated}");
        continue;
      }
      var state = double.tryParse(gd.sensors[i].state);
      if (lastChanged == null) {
        log.e("Can't parse state ${gd.sensors[i].state}");
        continue;
      }

      var lastChangedMapped = gd.mapNumber(lastChanged, now24, now, 0, 24);
//      var stateMapped = gd.mapNumber(state, stateMin, stateMax, 0, 12);
//
//      log.d("stateMapped $stateMapped lastChangedMapped $lastChangedMapped");

      flSpots.add(FlSpot(lastChangedMapped, state));
    }
  }

  void trimData() {
    log.d("trimData before ${gd.sensors.length}");
    List<Sensor> trimData = [];
    var overPopulate = gd.sensors.length ~/ 96;
    if (overPopulate > 1) {
      for (int i = 0; i < gd.sensors.length; i++) {
        if (i % overPopulate == 0) {
          trimData.add(gd.sensors[i]);
        }
      }
      log.d("trimData after ${trimData.length}");
      gd.sensors = trimData;
    }
  }
}

class SensorLowNumber extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    for (int i = 0; i < gd.sensors.length; i++) {
      var lastUpdated = DateTime.parse(gd.sensors[i].lastUpdated).toUtc();

      var widget = Container(
          height: 40,
          child: Text(DateFormat('dd-MMM kk:mm:ss').format(lastUpdated) +
              " - " +
              gd.sensors[i].state));
      widgets.add(widget);
    }

    return Column(
      children: widgets,
    );
  }
}

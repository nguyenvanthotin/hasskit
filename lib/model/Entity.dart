import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hasskit/helper/GeneralData.dart';
import 'package:hasskit/helper/Logger.dart';
import 'package:hasskit/helper/MaterialDesignIcons.dart';
import 'package:hasskit/helper/WebSocket.dart';
import 'package:hasskit/helper/LocaleHelper.dart';

enum EntityType {
  lightSwitches,
  climateFans,
  cameras,
  mediaPlayers,
  group,
  accessories,
  scriptAutomation,
}

class Entity {
  final String entityId;
  String deviceClass;
  String friendlyName;
  String icon;
  String state;
  //climate
  List<String> hvacModes;
  double minTemp;
  double maxTemp;
  double targetTempStep;
  double currentTemperature;
  double temperature;
  String fanMode;
  List<String> fanModes;
  String lastOnOperation;
  int deviceCode;
  String manufacturer;
//Fan
  List<String> speedList;
  bool oscillating;
  String speed;
  int angle;
  //Light
  int supportedFeatures;
  int brightness;
  List<int> rgbColor;
  int minMireds;
  int maxMireds;
  int colorTemp;
  //cover
  double currentPosition;
  //input_number
  double initial;
  double min;
  double max;
  double step;
  //media_player
  double volumeLevel;
  double mediaDuration;
  double mediaPosition;
  bool isVolumeMuted;
  String mediaContentType;
  String mediaTitle;
  String mediaArtist;
  String source;
  List<String> sourceList;
  String soundMode;
  List<String> soundModeList;
  String soundModeRaw;
  String entityPicture;

  Entity({
    this.entityId,
    this.deviceClass,
    this.friendlyName,
    this.icon,
    this.state,
    //climate
    this.hvacModes,
    this.minTemp,
    this.maxTemp,
    this.targetTempStep,
    this.currentTemperature,
    this.temperature,
    this.fanMode,
    this.fanModes,
    this.deviceCode,
    this.manufacturer,
    //fan
    this.speedList,
    this.oscillating,
    this.speed,
    this.angle,
    //light
    this.supportedFeatures,
    this.brightness,
    this.rgbColor,
    this.minMireds,
    this.maxMireds,
    this.colorTemp,
    //cover
    this.currentPosition,
    //intput_number
    this.initial,
    this.min,
    this.max,
    this.step,
//    media_player
    this.volumeLevel = 0,
    this.mediaDuration = -1,
    this.mediaPosition = -1,
    this.isVolumeMuted = false,
    this.mediaContentType = "",
    this.mediaTitle = "",
    this.mediaArtist = "",
    this.source = "",
    this.sourceList,
    this.soundMode = "",
    this.soundModeList,
    this.soundModeRaw = "",
    this.entityPicture = "",
  });

  factory Entity.fromJson(Map<String, dynamic> json) {
    try {
      if (json['entity_id'] == null) {
        return null;
      }
      return Entity(
        entityId: json['entity_id'].toString(),
        deviceClass: json['attributes']['device_class'].toString() != null
            ? json['attributes']['device_class'].toString()
            : "",
        icon: json['attributes']['icon'].toString() != null
            ? json['attributes']['icon'].toString()
            : "",
        friendlyName: json['attributes']['friendly_name'].toString() != null
            ? json['attributes']['friendly_name'].toString()
            : json['entity_id'].toString(),
        state: json['state'].toString(),
        //climate
        hvacModes: json['attributes']['hvac_modes'] != null
            ? List<String>.from(json['attributes']['hvac_modes'])
            : [],
        minTemp:
            double.tryParse(json['attributes']['min_temp'].toString()) != null
                ? double.tryParse(json['attributes']['min_temp'].toString())
                : 0,
        maxTemp:
            double.tryParse(json['attributes']['max_temp'].toString()) != null
                ? double.tryParse(json['attributes']['max_temp'].toString())
                : 0,
        targetTempStep: double.tryParse(
                    json['attributes']['target_temp_step'].toString()) !=
                null
            ? double.tryParse(json['attributes']['target_temp_step'].toString())
            : 1,
        temperature:
            double.tryParse(json['attributes']['temperature'].toString()) !=
                    null
                ? double.tryParse(json['attributes']['temperature'].toString())
                : 0,

        currentTemperature: double.tryParse(
                    json['attributes']['current_temperature'].toString()) !=
                null
            ? double.tryParse(
                json['attributes']['current_temperature'].toString())
            : 0,
        fanMode: json['attributes']['fan_mode'].toString() != null
            ? json['attributes']['fan_mode'].toString()
            : "",
        fanModes: json['attributes']['fan_modes'] != null
            ? List<String>.from(json['attributes']['fan_modes'])
            : [],
        deviceCode:
            int.tryParse(json['attributes']['device_code'].toString()) != null
                ? int.tryParse(json['attributes']['device_code'].toString())
                : 0,
        manufacturer: json['attributes']['manufacturer'].toString() != null
            ? json['attributes']['manufacturer'].toString()
            : "",
        //fan
        speedList: json['attributes']['speed_list'] != null
            ? List<String>.from(json['attributes']['speed_list'])
            : [],
        oscillating: json['attributes']['oscillating'] != null
            ? json['attributes']['oscillating']
            : false,
        speed: json['attributes']['direct_speed'].toString() != null
            ? json['attributes']['direct_speed'].toString()
            : json['attributes']['speed_level'].toString() != null
                ? json['attributes']['speed_level'].toString()
                : json['attributes']['speed'].toString() != null
                    ? json['attributes']['speed'].toString()
                    : "0",
        angle: int.tryParse(json['attributes']['angle'].toString()) != null
            ? int.tryParse(json['attributes']['angle'].toString())
            : 0,
        //supported_features
        supportedFeatures: int.tryParse(
                    json['attributes']['supported_features'].toString()) !=
                null
            ? int.tryParse(json['attributes']['supported_features'].toString())
            : 0,
        brightness:
            int.tryParse(json['attributes']['brightness'].toString()) != null
                ? int.tryParse(json['attributes']['brightness'].toString())
                : 0,
        rgbColor: json['attributes']['rgb_color'] != null
            ? List<int>.from(json['attributes']['rgb_color'])
            : [],
        minMireds:
            int.tryParse(json['attributes']['min_mireds'].toString()) != null
                ? int.tryParse(json['attributes']['min_mireds'].toString())
                : 0,
        maxMireds:
            int.tryParse(json['attributes']['max_mireds'].toString()) != null
                ? int.tryParse(json['attributes']['max_mireds'].toString())
                : 0,
        colorTemp:
            int.tryParse(json['attributes']['color_temp'].toString()) != null
                ? int.tryParse(json['attributes']['color_temp'].toString())
                : 0,
        currentPosition: double.tryParse(
                    json['attributes']['current_position'].toString()) !=
                null
            ? double.tryParse(json['attributes']['current_position'].toString())
            : null,
        //input_number
        initial:
            double.tryParse(json['attributes']['initial'].toString()) != null
                ? double.tryParse(json['attributes']['initial'].toString())
                : 0,
        min: double.tryParse(json['attributes']['min'].toString()) != null
            ? double.tryParse(json['attributes']['min'].toString())
            : 0,
        max: double.tryParse(json['attributes']['max'].toString()) != null
            ? double.tryParse(json['attributes']['max'].toString())
            : 0,
        step: double.tryParse(json['attributes']['step'].toString()) != null
            ? double.tryParse(json['attributes']['step'].toString())
            : 0,
        //media_player
        volumeLevel:
            double.tryParse(json['attributes']['volume_level'].toString()) !=
                    null
                ? double.tryParse(json['attributes']['volume_level'].toString())
                : 0,
        mediaDuration: double.tryParse(
                    json["attributes"]["media_duration"].toString()) !=
                null
            ? double.tryParse(json["attributes"]["media_duration"].toString())
            : -1,
        mediaPosition: double.tryParse(
                    json["attributes"]["media_position"].toString()) !=
                null
            ? double.tryParse(json["attributes"]["media_position"].toString())
            : -1,
        isVolumeMuted: json['attributes']['is_volume_muted'] != null
            ? json['attributes']['is_volume_muted']
            : false,
        mediaContentType:
            json['attributes']['media_content_type'].toString() != null
                ? json['attributes']['media_content_type'].toString()
                : "",
        mediaTitle: json['attributes']['media_title'].toString() != null
            ? json['attributes']['media_title'].toString()
            : "",
        mediaArtist: json['attributes']['media_artist'].toString() != null
            ? json['attributes']['media_artist'].toString()
            : "",
        source: json['attributes']['source'].toString() != null
            ? json['attributes']['source'].toString()
            : "",
        sourceList: json['attributes']['source_list'] != null
            ? List<String>.from(json['attributes']['source_list'])
            : [],
        soundMode: json['attributes']['sound_mode'].toString() != null
            ? json['attributes']['sound_mode'].toString()
            : "",
        soundModeList: json['attributes']['sound_mode_list'] != null
            ? List<String>.from(json['attributes']['sound_mode_list'])
            : [],
        soundModeRaw: json['attributes']['sound_mode_raw'].toString() != null
            ? json['attributes']['sound_mode_raw'].toString()
            : "",
        entityPicture: json['attributes']['entity_picture'].toString() != null
            ? json['attributes']['entity_picture'].toString()
            : "",
      );
    } catch (e) {
      log.e("Entity.fromJson newEntity $e");
      log.e("json $json");
      return null;
    }
  }

  toggleState() {
    var domain = entityId.split('.').first;
    if (domain == "group") domain = "homeassistant";
    var service = '';
    if (state == 'on' ||
        this.state == 'turning on...' ||
        domain == 'climate' && state != 'off') {
      this.state = 'turning off...';
      service = 'turn_off';
    } else if (state == 'off' || state == 'turning off...') {
      this.state = 'turning on...';
      service = 'turn_on';
    } else if (state == 'open' || state == 'opening...') {
      this.state = 'closing...';
      service = 'close_cover';
    } else if (state == 'closed' || state == 'closing...') {
      this.state = 'opening...';
      service = 'open_cover';
    } else if (state == 'locked' || state == 'locking...') {
      this.state = 'unlocking...';
      domain = "lock";
      service = 'unlock';
    } else if (state == 'unlocked' || state == 'unlocking...') {
      this.state = 'locking...';
      domain = "lock";
      service = 'lock';
    } else if (domain == "scene") {
      service = 'turn_on';
    }

    var outMsg = {
      "id": gd.socketId,
      "type": "call_service",
      "domain": domain,
      "service": service,
      "service_data": {"entity_id": entityId}
    };

    var message = json.encode(outMsg);
    webSocket.send(message);
  }

  EntityType get entityType {
    if (entityId.contains('fan.') || entityId.contains('climate.')) {
      return EntityType.climateFans;
    } else if (entityId.contains('camera.')) {
      return EntityType.cameras;
    } else if (entityId.contains('media_player.')) {
      return EntityType.mediaPlayers;
    } else if (entityId.contains('group.')) {
      return EntityType.group;
    } else if (entityId.contains('script.') ||
        entityId.contains('automation.') ||
        entityId.contains('scene.')) {
      return EntityType.scriptAutomation;
    } else if (entityId.contains('light.') ||
        entityId.contains('switch.') ||
        entityId.contains('cover.') ||
        entityId.contains('input_boolean.') ||
        entityId.contains('lock.') ||
        entityId.contains('vacuum.')) {
      return EntityType.lightSwitches;
    } else {
      return EntityType.accessories;
    }
  }

  int get fanModeIndex {
    return fanModes.indexOf(fanMode);
  }

  int get hvacModeIndex {
    return hvacModes.indexOf(state);
  }

  IconData get mdiIcon {
    return gd.mdiIcon(getDefaultIcon);
  }

  String get getOverrideIcon {
    if (gd.entitiesOverride[entityId] != null &&
        gd.entitiesOverride[entityId].icon != null &&
        gd.entitiesOverride[entityId].icon.length > 0) {
      return gd.entitiesOverride[entityId].icon;
    }
    return null;
  }

  String get getDefaultIcon {
    if (getOverrideIcon != null) {
      if (twoStateIcons(getOverrideIcon) != null)
        return twoStateIcons(getOverrideIcon);
      return getOverrideIcon;
    }

    if (icon != null && icon != "null" && twoStateIcons(icon) != null) {
      if (twoStateIcons(icon) != null) return twoStateIcons(icon);
      return icon;
    }

    String domain = entityId.split(".")[0];
    String stateTranslate = isStateOn ? "on" : "off";

//    log.d(
//        "getDefaultIcon entityId $entityId icon $icon domain $domain.$deviceClass.$stateTranslate state $state");

    if (domain != "null") {
      if (deviceClass != null &&
          MaterialDesignIcons.defaultIconsByDeviceClass[
                  "$domain.$deviceClass.$stateTranslate"] !=
              null) {
        return MaterialDesignIcons
            .defaultIconsByDeviceClass["$domain.$deviceClass.$stateTranslate"];
      }
      if (MaterialDesignIcons
              .defaultIconsByDeviceClass["$domain.$deviceClass"] !=
          null) {
        return MaterialDesignIcons
            .defaultIconsByDeviceClass["$domain.$deviceClass"];
      }
      if (MaterialDesignIcons
              .defaultIconsByDeviceClass["$domain.$stateTranslate"] !=
          null) {
        return MaterialDesignIcons
            .defaultIconsByDeviceClass["$domain.$stateTranslate"];
      }
    }

    //https://www.home-assistant.io/integrations/sensor/
    if (entityId.contains("sensor.")) {
      if (entityId.contains("battery")) return 'mdi:battery';
      if (entityId.contains("humidity")) return 'mdi:water-percent';
      if (entityId.contains("illuminance")) return 'mdi:brightness-6';
      if (entityId.contains("signal_strength")) return 'mdi:signal';
      if (entityId.contains("temperature")) return 'mdi:thermometer';
      if (entityId.contains("power")) return 'mdi:power';
      if (entityId.contains("pressure")) return 'mdi:gauge';
      if (entityId.contains("timestamp")) return 'mdi:clock';
    }

    //https://www.home-assistant.io/integrations/cover/
    if (entityId.contains("cover.")) {
      if (entityId.contains("awning")) return 'mdi:window-shutter';
      if (entityId.contains("blind")) return 'mdi:blinds';
      if (entityId.contains("curtain")) return 'mdi:blinds';
      if (entityId.contains("damper")) return 'mdi:window-close';
      if (entityId.contains("door")) return 'mdi:door-closed';
      if (entityId.contains("garage")) return 'mdi:garage';
      if (entityId.contains("shade")) return 'mdi:blinds';
      if (entityId.contains("shutter")) return 'mdi:window-shutter';
      if (entityId.contains("window")) return 'mdi:window-close';
    }

    if (MaterialDesignIcons.defaultIconsByDomains["$domain.$stateTranslate"] !=
        null) {
      return MaterialDesignIcons
          .defaultIconsByDomains["$domain.$stateTranslate"];
    }

    if (MaterialDesignIcons.defaultIconsByDomains["$domain"] != null) {
      return MaterialDesignIcons.defaultIconsByDomains["$domain"];
    }

    return 'mdi:help-circle';
  }

  String twoStateIcons(String currentIcon) {
    if (isStateOn && currentIcon == "mdi:bell") return "mdi:bell-ring";
    if (!isStateOn && currentIcon == "mdi:bell-ring") return "mdi:bell";

    if (isStateOn && currentIcon == "mdi:blinds") return "mdi:blinds-open";
    if (!isStateOn && currentIcon == "mdi:blinds-open") return "mdi:blinds";

    if (isStateOn && currentIcon == "mdi:door-closed") return "mdi:door-open";
    if (!isStateOn && currentIcon == "mdi:door-open") return "mdi:door-closed";

    if (isStateOn && currentIcon == "mdi:fan-off") return "mdi:fan";
    if (!isStateOn && currentIcon == "mdi:fan") return "mdi:fan-off";

    if (isStateOn && currentIcon == "mdi:garage") return "mdi:garage-open";
    if (!isStateOn && currentIcon == "mdi:garage-open") return "mdi:garage";

    if (isStateOn && currentIcon == "mdi:lightbulb") return "mdi:lightbulb-on";
    if (!isStateOn && currentIcon == "mdi:lightbulb-on") return "mdi:lightbulb";

    if (isStateOn && currentIcon == "mdi:lightbulb-outline")
      return "mdi:lightbulb-on-outline";
    if (!isStateOn && currentIcon == "mdi:lightbulb-on-outline")
      return "mdi:lightbulb-outline";

    if (isStateOn && currentIcon == "mdi:lock") return "mdi:lock-open";
    if (!isStateOn && currentIcon == "mdi:lock-open") return "mdi:lock";
    if (isStateOn && currentIcon == "mdi:window-closed")
      return "mdi:window-open";
    if (!isStateOn && currentIcon == "mdi:window-open")
      return "mdi:window-closed";
    if (isStateOn && currentIcon == "mdi:walk") return "mdi:run";
    if (!isStateOn && currentIcon == "mdi:run") return "mdi:walk";

    if (isStateOn && currentIcon == "mdi:window-shutter")
      return "mdi:window-shutter-open";
    if (!isStateOn && currentIcon == "mdi:window-shutter-open")
      return "mdi:window-shutter";

    return null;
  }

  bool get isStateOn {
    var stateLower = state.toLowerCase();
    if ([
      'on',
      'turning on...',
      'open',
      'opening...',
      'unlocked',
      'unlocking...'
    ].contains(stateLower)) {
      return true;
    }

    if ((entityId.split('.')[0] == 'climate' ||
            entityId.split('.')[0] == 'media_player') &&
        state.toLowerCase() != 'idle' &&
        state.toLowerCase() != 'off' &&
        state.toLowerCase() != 'unavailable') {
      return true;
    }
    return false;
  }

  bool get showAsBigButton {
    return entityType == EntityType.cameras;
  }

  String get getOverrideName {
    if (gd.entitiesOverride[entityId] != null &&
        gd.entitiesOverride[entityId].friendlyName != null &&
        gd.entitiesOverride[entityId].friendlyName.length > 0) {
      return gd.entitiesOverride[entityId].friendlyName;
    } else {
      return getFriendlyName;
    }
  }

  String get getFriendlyName {
    if (friendlyName != null) {
      return friendlyName;
    } else if (entityId != null) {
      return entityId;
    } else {
      return "???";
    }
  }

  //https://community.home-assistant.io/t/supported-features/43696
  List<String> supportedFeaturesLightList = [
    "SUPPORT_BRIGHTNESS",
    "SUPPORT_COLOR_TEMP",
    "SUPPORT_EFFECT",
    "SUPPORT_FLASH",
    "SUPPORT_RGB_COLOR",
    "SUPPORT_TRANSITION",
    "SUPPORT_XY_COLOR",
    "SUPPORT_WHITE_VALUE",
  ];
  String get getSupportedFeaturesLights {
    if (supportedFeatures == null) {
      return "";
    }
    var recVal = "";
    var binaryText = supportedFeatures.toRadixString(2);
    int index = 0;
    for (int i = binaryText.length; i > 0; i--) {
      var x = binaryText.substring(i - 1, i);
      if (x == "1") {
        recVal = recVal + supportedFeaturesLightList[index] + " | ";
      }
      index++;
    }
//    print("recVal $recVal");
    return recVal;
  }

  // https://github.com/home-assistant/home-assistant/blob/dev/homeassistant/components/media_player/const.py
  // [media_player.denon_avr_x3000] [state: on] 69004 SUPPORT_VOLUME_SET | SUPPORT_VOLUME_MUTE | SUPPORT_TURN_ON | SUPPORT_TURN_OFF | SUPPORT_VOLUME_STEP | SUPPORT_SELECT_SOURCE | SUPPORT_SELECT_SOUND_MODE |

  //[media_player.apple_tv] [state: unknown] 21427 SUPPORT_PAUSE | SUPPORT_SEEK | SUPPORT_PREVIOUS_TRACK | SUPPORT_NEXT_TRACK | SUPPORT_TURN_ON | SUPPORT_TURN_OFF | SUPPORT_PLAY_MEDIA | SUPPORT_STOP | SUPPORT_PLAY |

  //[media_player.living_room_tv] [state: unavailable] 21389 SUPPORT_PAUSE | SUPPORT_VOLUME_SET | SUPPORT_VOLUME_MUTE | SUPPORT_TURN_ON | SUPPORT_TURN_OFF | SUPPORT_PLAY_MEDIA | SUPPORT_STOP | SUPPORT_PLAY |

  //Available services: turn_on, turn_off, toggle, volume_up, volume_down, volume_set, volume_mute, media_play_pause, media_play, media_pause, media_stop, media_next_track, media_previous_track, clear_playlist, shuffle_set

  List<String> supportedFeaturesMediaPlayerList = [
    "SUPPORT_PAUSE",
    "SUPPORT_SEEK",
    "SUPPORT_VOLUME_SET",
    "SUPPORT_VOLUME_MUTE",
    "SUPPORT_PREVIOUS_TRACK",
    "SUPPORT_NEXT_TRACK",
    "",
    "SUPPORT_TURN_ON",
    "SUPPORT_TURN_OFF",
    "SUPPORT_PLAY_MEDIA",
    "SUPPORT_VOLUME_STEP",
    "SUPPORT_SELECT_SOURCE",
    "SUPPORT_STOP",
    "SUPPORT_CLEAR_PLAYLIST",
    "SUPPORT_PLAY",
    "SUPPORT_SHUFFLE_SET",
    "SUPPORT_SELECT_SOUND_MODE",
  ];
  String get getSupportedFeaturesMediaPlayer {
    if (supportedFeatures == null) {
      return "";
    }
    var recVal = "";
    var binaryText = supportedFeatures.toRadixString(2);
    int index = 0;
    for (int i = binaryText.length; i > 0; i--) {
      var x = binaryText.substring(i - 1, i);
      if (x == "1") {
        recVal = recVal + supportedFeaturesMediaPlayerList[index] + " | ";
      }
      index++;
    }
//    print("recVal $recVal");
    return recVal;
  }

  String get getStateDisplay {
    if (isStateOn && entityId.contains("fan.")) {
      if (speed != null && speed.length > 0 && speed != "null") return speed;
    }
    return state;
  }

  String getStateDisplayTranslated(BuildContext context) {
    if (isStateOn && entityId.contains("fan.")) {
      if (speed != null && speed.length > 0 && speed != "null") {
        if (speed.toLowerCase() == "high")
          return Translate.getString("states.fan_high", context);
        if (speed.toLowerCase() == "mediumhigh")
          return Translate.getString("states.fan_high_medium", context);
        if (speed.toLowerCase() == "medium")
          return Translate.getString("states.fan_medium", context);
        if (speed.toLowerCase() == "mediumlow")
          return Translate.getString("states.fan_medium_low", context);
        if (speed.toLowerCase() == "low")
          return Translate.getString("states.fan_low", context);
        if (speed.toLowerCase() == "lowest")
          return Translate.getString("states.fan_lowest", context);
        return speed;
      }
    }

    if (state.toLowerCase() == "on")
      return Translate.getString("states.on", context);
    if (state.toLowerCase() == "turning on...")
      return Translate.getString("states.turning_on", context);
    if (state.toLowerCase() == "off")
      return Translate.getString("states.off", context);
    if (state.toLowerCase() == "turning off...")
      return Translate.getString("states.turning_off", context);
    if (state.toLowerCase() == "closed")
      return Translate.getString("states.closed", context);
    if (state.toLowerCase() == "closing...")
      return Translate.getString("states.closing", context);
    if (state.toLowerCase() == "open")
      return Translate.getString("states.open", context);
    if (state.toLowerCase() == "opening...")
      return Translate.getString("states.opening", context);
    if (state.toLowerCase() == "locked")
      return Translate.getString("states.locked", context);
    if (state.toLowerCase() == "locking...")
      return Translate.getString("states.locking", context);
    if (state.toLowerCase() == "unlocked")
      return Translate.getString("states.unlocked", context);
    if (state.toLowerCase() == "unlocking...")
      return Translate.getString("states.unlocking", context);
    if (state.toLowerCase() == "disarmed")
      return Translate.getString("states.disarmed", context);
    if (state.toLowerCase().contains("armed")) {
      if (state.toLowerCase().contains("away"))
        return Translate.getString("states.armed_away", context);
      if (state.toLowerCase().contains("home"))
        return Translate.getString("states.armed_home", context);
      if (state.toLowerCase().contains("night"))
        return Translate.getString("states.armed_night", context);
      return Translate.getString("states.armed", context);
    }
    if (state.toLowerCase().contains("pending"))
      return Translate.getString("states.arm_pending", context);

    return state;
  }

  double get getTemperature {
    if (temperature != null) return temperature;
    if (currentTemperature != null) return currentTemperature;
    return 0;
  }
}

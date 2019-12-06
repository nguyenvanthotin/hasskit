import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:hasskit/helper/GeneralData.dart';
import 'package:hasskit/helper/Logger.dart';
import 'package:hasskit/helper/MaterialDesignIcons.dart';
import 'package:hasskit/helper/ThemeInfo.dart';
import 'package:hasskit/helper/LocaleHelper.dart';

class EntityControlToggle extends StatefulWidget {
  final String entityId;

  const EntityControlToggle({@required this.entityId});
  @override
  _EntityControlToggleState createState() => _EntityControlToggleState();
}

class _EntityControlToggleState extends State<EntityControlToggle> {
  double buttonTotalHeight = 300.0;
  double upperPartHeight = 30.0;
  double buttonWidth = 90.0;
  double buttonHalfHeight;
  double buttonFullHeight;
  double buttonValue;
  double currentPosX;
  double currentPosY;
  double startPosX;
  double startPosY;
  double diffY = 0;
  double snap = 10;

  @override
  void initState() {
    buttonFullHeight = (buttonTotalHeight - upperPartHeight);
    buttonHalfHeight = buttonTotalHeight / 2;
    if (gd.entities[widget.entityId].isStateOn) {
      buttonValue = buttonFullHeight;
    } else {
      buttonValue = buttonHalfHeight;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      onVerticalDragStart: (DragStartDetails details) =>
          _onVerticalDragStart(context, details),
      onVerticalDragUpdate: (DragUpdateDetails details) =>
          _onVerticalDragUpdate(context, details),
      onVerticalDragEnd: (DragEndDetails details) =>
          _onVerticalDragEnd(context, details),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              Container(
                width: buttonWidth,
                height: buttonTotalHeight,
                decoration: BoxDecoration(
                  color: gd.entities[widget.entityId].isStateOn
                      ? ThemeInfo.colorIconActive
                      : ThemeInfo.colorIconInActive,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 0.0, // has the effect of softening the shadow
                      spreadRadius:
                          1.0, // has the effect of extending the shadow
                      offset: Offset(
                        0.0, // horizontal, move right 10
                        0.0, // vertical, move down 10
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  alignment: Alignment.topCenter,
                  width: buttonWidth,
                  height: buttonValue,
                  padding: const EdgeInsets.all(2.0),
                  decoration: new BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    color: gd.entities[widget.entityId].isStateOn
                        ? Colors.white.withOpacity(1)
                        : Colors.white.withOpacity(1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                          MaterialDesignIcons.getIconDataFromIconName(
                              gd.entities[widget.entityId].getDefaultIcon),
                          size: 70,
                          color: gd.entities[widget.entityId].isStateOn
                              ? ThemeInfo.colorIconActive
                              : ThemeInfo.colorIconInActive),
                      Text(
                        gd.textToDisplay(gd.entities[widget.entityId]
                            .getStateDisplayTranslated(context)),
                        style: ThemeInfo.textStatusButtonActive,
                        maxLines: 1,
                        textScaleFactor:
                            gd.textScaleFactor * 3 / gd.baseSetting.itemsPerRow,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                child: Container(
                  width: buttonWidth,
                  height: upperPartHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: RequireSlideToOpen(entityId: widget.entityId),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  _onVerticalDragStart(BuildContext context, DragStartDetails details) {
    final RenderBox box = context.findRenderObject();
    final Offset localOffset = box.globalToLocal(details.globalPosition);
    setState(() {
      startPosX = localOffset.dx;
      startPosY = localOffset.dy;
//      log.d(
//          "_onVerticalDragStart startPosX ${startPosX.toStringAsFixed(0)} startPosY ${startPosY.toStringAsFixed(0)}");
    });
  }

  _onVerticalDragEnd(BuildContext context, DragEndDetails details) {
    setState(
      () {
        log.d("_onVerticalDragEnd");
        diffY = 0;
        if (gd.entities[widget.entityId].isStateOn) {
          buttonValue = buttonFullHeight;
        } else {
          buttonValue = buttonHalfHeight;
        }
      },
    );
  }

  _onVerticalDragUpdate(BuildContext context, DragUpdateDetails details) {
    final RenderBox box = context.findRenderObject();
    final Offset localOffset = box.globalToLocal(details.globalPosition);
    setState(() {
      currentPosX = localOffset.dx;
      currentPosY = localOffset.dy;
      diffY = startPosY - currentPosY;
      var stateValue;

      if (gd.entities[widget.entityId].isStateOn) {
        stateValue = buttonFullHeight;
        if (diffY > 0) diffY = 0;
        if (stateValue + diffY < buttonHalfHeight + snap)
          gd.toggleStatus(gd.entities[widget.entityId]);
      }

      if (!gd.entities[widget.entityId].isStateOn) {
        stateValue = buttonHalfHeight;
        if (diffY < 0) diffY = 0;
        if (stateValue + diffY > buttonFullHeight - snap)
          gd.toggleStatus(gd.entities[widget.entityId]);
      }

      buttonValue = stateValue + diffY;

      print("yDiff $diffY");
    });
  }
}

class RequireSlideToOpen extends StatelessWidget {
  final String entityId;

  const RequireSlideToOpen({@required this.entityId});
  @override
  Widget build(BuildContext context) {
    if (!entityId.contains("cover.")) {
      return Container();
    }

    bool required = false;

    if (gd.entitiesOverride[entityId] != null &&
        gd.entitiesOverride[entityId].openRequireAttention != null &&
        gd.entitiesOverride[entityId].openRequireAttention == true) {
      required = true;
    }

    return InkWell(
      onTap: () {
        gd.requireSlideToOpenAddRemove(entityId);
        Flushbar(
          title: required
              ? Translate.getString(
                  "toggle.require_slide_open_disabled", context)
              : Translate.getString(
                  "toggle.require_slide_open_enabled", context),
          message: required
              ? "${gd.textToDisplay(gd.entities[entityId].getOverrideName)} ${Translate.getString('toggle.1_touch', context)}"
              : "${Translate.getString('toggle.prevent_accidentally_open', context)} ${gd.textToDisplay(gd.entities[entityId].getOverrideName)}",
          duration: Duration(seconds: 3),
        )..show(context);
      },
      child: Container(
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Icon(
            required
                ? MaterialDesignIcons.getIconDataFromIconName("mdi:lock")
                : MaterialDesignIcons.getIconDataFromIconName("mdi:lock-open"),
            color: required
                ? ThemeInfo.colorIconActive
                : ThemeInfo.colorIconInActive,
            size: 100,
          ),
        ),
      ),
    );
  }
}

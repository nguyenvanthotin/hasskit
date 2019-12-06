import 'package:duration/duration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widgets/flutter_widgets.dart';
import 'package:hasskit/helper/GeneralData.dart';
import 'package:hasskit/helper/ThemeInfo.dart';
import 'package:hasskit/model/CameraInfo.dart';
import 'package:provider/provider.dart';

class EntityCamera extends StatelessWidget {
  final String entityId;
  final Color borderColor;
  final Function onTapCallback;
  final Function onLongPressCallback;

  const EntityCamera({
    @required this.entityId,
    @required this.borderColor,
    @required this.onTapCallback,
    @required this.onLongPressCallback,
  });

  @override
  Widget build(BuildContext context) {
    CameraInfo cameraInfo = gd.cameraInfoGet(entityId);

    return Selector<GeneralData, String>(
      selector: (_, generalData) => ""
          "${generalData.cameraInfos[entityId].updatedTime}"
          "",
      builder: (context, data, child) {
        var timeDiff = DateTime.now().difference(cameraInfo.updatedTime);
//        log.d("EntityCamera.Selector $entityId timeDiff $timeDiff");
        return VisibilityDetector(
          key: Key(entityId),
          onVisibilityChanged: (VisibilityInfo info) {
            if (info.visibleFraction > 0.5) {
              if (!gd.cameraInfosActive.contains(entityId)) {
                gd.cameraInfosActive.add(entityId);
                gd.cameraInfosUpdate(entityId);
              }
            } else {
              if (gd.cameraInfosActive.contains(entityId)) {
                gd.cameraInfosActive.remove(entityId);
              }
            }
          },
          child: InkWell(
            onTap: onTapCallback,
            onLongPress: onLongPressCallback,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          child: Stack(
                            fit: StackFit.expand,
                            alignment: Alignment.center,
                            children: <Widget>[
                              Container(color: ThemeInfo.colorBackgroundDark),
                              Image(
                                image: cameraInfo.previousImage,
                                fit: BoxFit.cover,
                              ),
                              Image(
                                image: cameraInfo.currentImage,
                                fit: BoxFit.cover,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: borderColor != Colors.transparent
                              ? borderColor
                              : ThemeInfo.colorBottomSheet.withOpacity(0.9),
                          borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8)),
                        ),
                        padding: EdgeInsets.all(8),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                //"${Translate.getString('global.last_update', context)}: ${printDuration(timeDiff, abbreviated: true, tersity: DurationTersity.second, delimiter: ', ', conjugation: ' and ')} ago"
                                gd.entities[entityId].getOverrideName,
                                style: Theme.of(context).textTheme.body1,
                                textScaleFactor: gd.textScaleFactor,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            timeDiff.inDays >= 1
                                ? Text(
                                    "...",
                                    style: Theme.of(context).textTheme.body1,
                                    textScaleFactor: gd.textScaleFactor,
                                  )
                                : timeDiff.inSeconds < 20
                                    ? Text(
                                        "Few seconds ago",
                                        style:
                                            Theme.of(context).textTheme.body1,
                                        textScaleFactor: gd.textScaleFactor,
                                      )
                                    : Text(
                                        "${printDuration(timeDiff, abbreviated: false, tersity: DurationTersity.second, spacer: ' ', delimiter: ' ', conjugation: ' and ')} ago",
                                        style:
                                            Theme.of(context).textTheme.body1,
                                        textScaleFactor: gd.textScaleFactor,
                                      ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

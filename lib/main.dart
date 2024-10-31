import 'dart:developer';

import 'package:flutter/material.dart';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (e) {
              return Container(
                constraints: const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.primaries[e.hashCode % Colors.primaries.length],
                ),
                child: Center(child: Icon(e, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dock of the reorderable [items].
class Dock<T> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate the [icons].
class _DockState<T> extends State<Dock<T>> {
  /// [capturePoint] is the point from where the drag started
  Offset? capturePoint;

  /// [atindex] is the index where the dragged item is hovering
  int atindex = -1;

  /// [pickedIndex] is the index of the picked item
  int pickedIndex = -1;

  /// [picked] is a boolean to check if the item is picked
  bool picked = false;

  /// [showEndSpacing] is specialy for the last item to show the spacing at the end
  bool showEndSpacing = false;

  /// [outOfDock] is a boolean to check if the item is out of the dock
  bool outOfDock = false;

  /// [T] items being manipulated.
  List<T> icons = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    icons.addAll(widget.items);
  }

  void onIteamDrop(DragTargetDetails<Object?> details) {
    log("dropped at ${details.offset} $outOfDock");
    setState(() {
      /// these 3 lines of code will swap the picked item with the item where it is hovering if the
      /// icon is dropped in the dock
      T temp = icons[pickedIndex];
      icons.removeAt(pickedIndex);
      int newIndex = atindex == 0
          ? 0

          /// To check if the item is being dropped at the end of the dock
          : showEndSpacing
              ? atindex
              : pickedIndex < atindex
                  ? atindex - 1
                  : atindex;

      icons.insert(newIndex, temp);

      /// To reset the values of the variables
      atindex = -1;
      pickedIndex = -1;
      capturePoint = null;
      picked = false;
      showEndSpacing = false;
      outOfDock = false;
    });
  }

  void movingItem(DragTargetDetails<Object?> details) {
    /// this if condition is to check if the drag is started
    /// and it will capture the point from where the drag started
    /// and will never change the capture point until the drag is completed
    /// this will help to calculate the difference between the starting point and the current point
    if (capturePoint == null) {
      /// this will get the starting point of the drag
      capturePoint = details.offset;

      /// this will get the index of the picked item
      pickedIndex = icons.indexOf(details.data as T);
    }

    /// this will calculate the difference between the starting point and the current point
    double differenceBetweenPoints = details.offset.dx - capturePoint!.dx;

    setState(() {
      picked = true;

      // this will set the value of outOfDock to false when the item is in the dock
      if (outOfDock) {
        outOfDock = false;
      }

      /// this will calculate the index where the dragged item is hovering
      /// I have divided the difference between the points by 48 as the width of the item is 50
      atindex = pickedIndex + (differenceBetweenPoints ~/ 48);

      /// this will check if the item is being dropped at the end of the dock
      if (atindex + 1 > icons.length) {
        showEndSpacing = true;
        atindex = icons.length - 1;
      }

      /// [atindex < 0] is to check if the item is being dropped at the start of the dock
      /// difference of offsets can be negative due to the drag animation giving room to drag in dock
      else if (atindex < 0) {
        log("at index $atindex pickedfrom $pickedIndex");
        atindex = 0;
      } else {
        showEndSpacing = false;
      }

      /// this log will help to debug the index where the dragged item is hovering
      log("at index $atindex , pickedfrom $pickedIndex ${(pickedIndex + 1 == atindex)}");
    });
  }

  void whenItemLeavesDock(Object? data) {
    /// To set the value of [outOfDock] to true when the item is out of the dock
    setState(() {
      outOfDock = true;
      log("out of dock");
    });
  }

  @override
  Widget build(BuildContext context) {
    /// [animationDuration] is the animation curve for everyaniamtion that happens in dock
    const Curve animationCurve = Curves.fastOutSlowIn;

    /// [animationDuration] is the duration of the animation
    const Duration animationDuration = Duration(milliseconds: 450);

    /// [childWhenDraggingAnimationTrigger] is a boolean to check if the item is being dragged
    bool childWhenDraggingAnimationTrigger =
        atindex == pickedIndex && !outOfDock;

    bool itemLeftSpacingAnimationTrigger(int index) =>
        atindex == index && !showEndSpacing && !outOfDock;
    bool itemRightSpacingAnimationTrigger(int index) =>
        showEndSpacing && (index == icons.length - 1) && !outOfDock;

    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black12,
        ),
        padding: const EdgeInsets.all(4),
        child: DragTarget(
          onLeave: whenItemLeavesDock,
          onAcceptWithDetails: onIteamDrop,
          onMove: movingItem,
          builder: (context, candidateData, rejectedData) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                icons.length,
                (index) {
                  return Draggable<Object>(
                    data: icons[index],
                    feedback: widget.builder(icons[index]),
                    childWhenDragging: AnimatedContainer(
                      margin: EdgeInsets.all(
                          childWhenDraggingAnimationTrigger ? 8 : 0),
                      duration: animationDuration,
                      curve: animationCurve,
                      width: childWhenDraggingAnimationTrigger ? 48 : 0,
                      height: 48,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: animationDuration,
                          curve: animationCurve,
                          margin: EdgeInsets.all(
                              itemLeftSpacingAnimationTrigger(index) ? 8 : 0),

                          /// Here I have checked if the item is being hovered and the item is not out of the dock
                          width:
                              itemLeftSpacingAnimationTrigger(index) ? 48 : 0,
                          height: 48,
                        ),
                        widget.builder(
                          icons[index],
                        ),
                        AnimatedContainer(
                          duration: animationDuration,
                          curve: animationCurve,
                          margin: EdgeInsets.all(
                              itemRightSpacingAnimationTrigger(index) ? 8 : 0),
                          width:
                              itemRightSpacingAnimationTrigger(index) ? 48 : 0,
                          height: 48,
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ));
  }
}

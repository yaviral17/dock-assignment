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

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black12,
        ),
        padding: const EdgeInsets.all(4),
        child: DragTarget(
          onLeave: (data) {
            /// To set the value of [outOfDock] to true when the item is out of the dock
            setState(() {
              outOfDock = true;
            });
          },
          onAcceptWithDetails: (details) {
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
          },
          onMove: (details) {
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
            double differenceBetweenPoints =
                details.offset.dx - capturePoint!.dx;

            setState(() {
              picked = true;
              outOfDock = false;

              /// this will calculate the index where the dragged item is hovering
              /// I have divided the difference between the points by 48 as the width of the item is 50
              atindex = pickedIndex + (differenceBetweenPoints ~/ 48);

              if (atindex + 1 > icons.length) {
                showEndSpacing = true;
                atindex = icons.length - 1;
              } else {
                showEndSpacing = false;
              }

              /// this log will help to debug the index where the dragged item is hovering
              log("at index $atindex , pickedfrom $pickedIndex ${(pickedIndex + 1 == atindex)}");
            });
          },
          builder: (context, candidateData, rejectedData) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                icons.length,
                (index) {
                  return Draggable<Object>(
                    data: icons[index],
                    feedback: widget.builder(icons[index]),

                    /// [atindex == pickedIndex] will help in creating a space for item when it's being hovered from where it was picked
                    childWhenDragging: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.fastEaseInToSlowEaseOut,
                      width: atindex == pickedIndex && !outOfDock ? 48 : 0,
                      height: 48,
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.fastEaseInToSlowEaseOut,

                          /// Here I have checked if the item is being hovered and the item is not out of the dock
                          width:
                              atindex == index && !showEndSpacing && !outOfDock
                                  ? 48
                                  : 0,
                          height: 48,
                        ),
                        widget.builder(
                          icons[index],
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.fastEaseInToSlowEaseOut,
                          width: showEndSpacing &&
                                  (index == icons.length - 1) &&
                                  !outOfDock
                              ? 48
                              : 0,
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

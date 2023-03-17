import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

@WidgetbookUseCase(name: 'String Selector', type: DropdownSelector)
Widget wbDropdownSelector(BuildContext context) {
  return tiamat.Tile.low2(
    child: Padding(
      padding: EdgeInsets.all(10.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: DropdownSelector<String>(
                items: ["Alpha", "Bravo", "Charlie", "Delta"],
                itemBuilder: (item) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: tiamat.Text(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

@WidgetbookUseCase(name: 'Avatar Selector', type: DropdownSelector)
Widget wbDropdownAvatarSelector(BuildContext context) {
  return tiamat.Tile(
    child: Padding(
      padding: EdgeInsets.all(10.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                child: DropdownSelector<ImageProvider>(
                  items: [
                    AssetImage("assets/images/placeholder/generic/checker_purple.png"),
                    AssetImage("assets/images/placeholder/generic/checker_red.png"),
                    AssetImage("assets/images/placeholder/generic/checker_green.png"),
                    AssetImage("assets/images/placeholder/generic/checker_orange.png")
                  ],
                  itemBuilder: (item) {
                    return Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: tiamat.Avatar.medium(image: item),
                        ),
                        tiamat.Text.labelEmphasised("Avatar with text")
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class DropdownSelector<T> extends StatefulWidget {
  const DropdownSelector(
      {required this.items,
      required this.itemBuilder,
      this.itemHeight,
      this.onItemSelected,
      this.defaultIndex = 0,
      super.key});
  final List<T> items;
  final Widget Function(T item) itemBuilder;
  final void Function(T item)? onItemSelected;
  final int defaultIndex;
  final double? itemHeight;

  @override
  State<DropdownSelector<T>> createState() => _DropdownSelectorState<T>();
}

class _DropdownSelectorState<T> extends State<DropdownSelector<T>> {
  late T value;

  @override
  void initState() {
    value = widget.items[widget.defaultIndex];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Material(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Theme.of(context).highlightColor, width: 1.4),
        ),
        color: Colors.transparent,
        child: DropdownButtonHideUnderline(
          child: DropdownButton(
            itemHeight: widget.itemHeight,
            focusColor: Colors.transparent,
            value: value,
            items: widget.items.map((value) {
              return DropdownMenuItem(
                alignment: Alignment.centerLeft,
                value: value,
                child: widget.itemBuilder(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                value = newValue!;
              });
              widget.onItemSelected?.call(newValue!);
            },
          ),
        ),
      ),
    );
  }
}

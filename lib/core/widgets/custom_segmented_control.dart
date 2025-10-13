import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mymink/core/constants/colors.dart';

class CustomSegmentedControl extends StatefulWidget {
  /// List of titles to display as segments.
  final List<String> segments;

  /// The initially selected segment.
  final String initialSelectedSegment;

  /// Callback function when the selection changes.
  final ValueChanged<String> onValueChanged;

  /// Optional padding for each segment.
  final EdgeInsets segmentPadding;

  /// Optional colors for customization.
  final Color selectedColor;
  final Color unselectedColor;
  final Color borderColor;
  final TextStyle? textStyle;

  const CustomSegmentedControl({
    Key? key,
    required this.segments,
    required this.initialSelectedSegment,
    required this.onValueChanged,
    this.segmentPadding =
        const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
    this.selectedColor = AppColors.primaryRed,
    this.unselectedColor = Colors.black,
    this.borderColor = Colors.black,
    this.textStyle,
  }) : super(key: key);

  @override
  _CustomSegmentedControlState createState() => _CustomSegmentedControlState();
}

class _CustomSegmentedControlState extends State<CustomSegmentedControl> {
  late String _selectedSegment;

  @override
  void initState() {
    super.initState();
    _selectedSegment = widget.initialSelectedSegment;
  }

  @override
  Widget build(BuildContext context) {
    // Build a map of segment title to widget
    Map<String, Widget> children = {
      for (var segment in widget.segments)
        segment: Padding(
          padding: widget.segmentPadding,
          child: Text(
            segment,
            style: widget.textStyle ??
                const TextStyle(
                  color: Colors.white,
                ),
          ),
        )
    };

    return CupertinoSegmentedControl<String>(
      padding: const EdgeInsets.all(0),
      children: children,
      groupValue: _selectedSegment,
      onValueChanged: (String value) {
        setState(() {
          _selectedSegment = value;
        });
        widget.onValueChanged(value);
      },
      selectedColor: widget.selectedColor,
      unselectedColor: widget.unselectedColor,
      pressedColor: const Color.fromARGB(106, 210, 0, 0),
      borderColor: widget.borderColor,
    );
  }
}

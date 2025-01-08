import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class MemberSelectWidget extends StatefulWidget {
  final List<String> members;
  final List<String> selectedMembers;

  const MemberSelectWidget({
    Key? key,
    required this.members,
    required this.selectedMembers,
  }) : super(key: key);

  @override
  _MemberSelectWidgetState createState() => _MemberSelectWidgetState();
}

class _MemberSelectWidgetState extends State<MemberSelectWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: MultiSelectDialogField(
        items:
            widget.members
                .map((member) => MultiSelectItem(member, member))
                .toList(),
        initialValue: widget.selectedMembers,
        listType: MultiSelectListType.CHIP,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 1.0),
          borderRadius: BorderRadius.circular(14.0),
        ),
        buttonIcon: const Icon(Icons.group, color: Colors.black),
        buttonText: const Text(
          "Select Members",
          style: TextStyle(fontSize: 14.0, color: Colors.grey),
        ),
        title: const Text("Select Members"),
        selectedColor: Colors.blue,
        selectedItemsTextStyle: const TextStyle(
          color: Colors.white, // Ensure text is visible on blue background
        ),
        chipDisplay: MultiSelectChipDisplay(
          chipColor: Colors.blue.shade100,
          textStyle: const TextStyle(color: Colors.black),
        ),
        onConfirm: (values) {
          setState(() {
            widget.selectedMembers.clear();
            widget.selectedMembers.addAll(values.cast<String>());
          });
        },
        validator: (values) {
          if (values == null || values.isEmpty) {
            return 'Please select at least one member';
          }
          return null;
        },
      ),
    );
  }
}

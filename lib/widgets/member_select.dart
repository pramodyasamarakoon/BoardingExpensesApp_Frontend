import 'package:flutter/material.dart';

class MemberSelectWidget extends StatefulWidget {
  final List<String> members; // List of available members (names)
  final List<String> selectedMembers; // List of selected member IDs
  final ValueChanged<List<String>>? onSelectionChanged; // Callback

  const MemberSelectWidget({
    Key? key,
    required this.members,
    required this.selectedMembers,
    this.onSelectionChanged,
  }) : super(key: key);

  @override
  _MemberSelectWidgetState createState() => _MemberSelectWidgetState();
}

class _MemberSelectWidgetState extends State<MemberSelectWidget> {
  List<String> _selectedMembers = [];

  @override
  void initState() {
    super.initState();
    _selectedMembers = List.from(widget.selectedMembers);
  }

  void _toggleSelection(String member) {
    setState(() {
      if (_selectedMembers.contains(member)) {
        _selectedMembers.remove(member);
      } else {
        _selectedMembers.add(member);
      }
    });

    if (widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(_selectedMembers);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Members",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Wrap(
          spacing: 8.0,
          children:
              widget.members.map((member) {
                final isSelected = _selectedMembers.contains(member);
                return ChoiceChip(
                  label: Text(member),
                  selected: isSelected,
                  onSelected: (_) => _toggleSelection(member),
                );
              }).toList(),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class SearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const SearchField({
    super.key,
    this.hintText = 'Search...',
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller!.clear();
                    onChanged('');
                  },
                )
              : null,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}

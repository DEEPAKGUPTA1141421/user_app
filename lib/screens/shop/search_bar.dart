import 'package:flutter/material.dart';

class SearchBar extends StatelessWidget {
  final String? placeholder;
  final String? value;
  final ValueChanged<String>? onChange;
  final String? className; // Not used in Flutter but kept for parity

  const SearchBar({
    super.key,
    this.placeholder = "Search...",
    this.value,
    this.onChange,
    this.className,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: TextEditingController(text: value),
        onChanged: onChange,
        decoration: InputDecoration(
          hintText: placeholder,
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          filled: true,
          fillColor: Colors.white, // bg-card equivalent
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
                color: Colors.grey.shade300), // border-border equivalent
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide:
                BorderSide(color: Colors.blue), // primary color when focused
          ),
        ),
      ),
    );
  }
}

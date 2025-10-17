import 'package:flutter/material.dart';

class Textarea extends StatelessWidget {
  final String? placeholder;
  final String? value;
  final ValueChanged<String>? onChange;
  final bool? enabled;

  const Textarea({
    super.key,
    this.placeholder,
    this.value,
    this.onChange,
    this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value),
      onChanged: onChange,
      enabled: enabled ?? true,
      minLines: 3,
      maxLines: null, // allows auto expanding
      decoration: InputDecoration(
        hintText: placeholder,
        filled: true,
        fillColor: Colors.white, // equivalent to bg-background
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey), // border-input
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: Colors.blue), // focus-visible:ring
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey), // normal border
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        hintStyle: const TextStyle(
            color: Colors.grey), // placeholder:text-muted-foreground
      ),
      style: const TextStyle(fontSize: 14), // text-sm
    );
  }
}

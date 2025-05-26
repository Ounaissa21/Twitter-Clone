import 'package:flutter/material.dart';
import 'package:twitter_clone/theme/pallete.dart';

class TwitterAuthField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isPassword;

  const TwitterAuthField({
    super.key,
    required this.controller,
    required this.hintText,
    this.isPassword = false,
  });

  @override
  State<TwitterAuthField> createState() => _TwitterAuthFieldState();
}

class _TwitterAuthFieldState extends State<TwitterAuthField> {
  bool _isFocused = false;
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _isFocused ? Colors.blue : Colors.grey.shade700,
          width: _isFocused ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: widget.isPassword ? _obscureText : false,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
        decoration: InputDecoration(
          labelText: widget.hintText,
          labelStyle: TextStyle(
            color: _isFocused ? Colors.blue : Colors.grey,
            fontSize: _isFocused ? 14 : 18,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,
        ),
        onTap: () {
          setState(() {
            _isFocused = true;
          });
        },
        onTapOutside: (event) {
          setState(() {
            _isFocused = false;
          });
        },
      ),
    );
  }
}
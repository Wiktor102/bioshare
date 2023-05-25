import 'package:flutter/material.dart';

class CustomInputDecoration extends InputDecoration {
  CustomInputDecoration(context,
      {Icon? prefixIcon, String? labelText, String? hintText})
      : super(
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            labelStyle: TextStyle(
              color: Theme.of(context).primaryColorDark.withOpacity(0.7),
            ),
            prefixIcon: prefixIcon,
            labelText: labelText,
            hintText: hintText);
}

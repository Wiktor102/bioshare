import 'package:flutter/material.dart';

class CustomInputDecoration extends InputDecoration {
  CustomInputDecoration(context, {IconData? prefixIcon, String? labelText, String? hintText})
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
            fillColor: Theme.of(context).colorScheme.background,
            prefixIconColor: Theme.of(context).colorScheme.onSurface,
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: Theme.of(context).colorScheme.primary,
            ),
            labelText: labelText,
            hintText: hintText);
}

import 'package:flutter/material.dart';

const primaryColor = Colors.white;
const whiteColor = Color(0xFFF3F4F8);
const yellowColor = Color(0xFFF7EA00);

const secondaryColor = Color(0xFF3A665E);
const greyColor = Color(0xFF707070);
const blackColor = Color(0xFF101010);
const errorColor = Color(0xFFee1632);

const double defaultPadding = 18.0;

final boxShadow = BoxShadow(
    blurRadius: 10,
    color: Colors.black.withOpacity(0.1),
    offset: const Offset(1, 3));

const textFieldInputDecorator = InputDecoration(
  labelStyle: TextStyle(color: greyColor),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: greyColor),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: blackColor),
  ),
  border: OutlineInputBorder(
    borderSide: BorderSide(color: blackColor),
    borderRadius: BorderRadius.all(
      Radius.circular(12),
    ),
  ),
);

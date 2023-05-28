import 'package:flutter/material.dart';

class NoAnimPageRoute<T> extends MaterialPageRoute<T>{
  NoAnimPageRoute({required WidgetBuilder builder}) : super(builder: builder);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}
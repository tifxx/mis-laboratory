import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdaptiveFlatButton extends StatelessWidget {
  final String text;
  final VoidCallback handler;

  AdaptiveFlatButton(this.text, this.handler);

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? CupertinoButton(
            child: Text(text),
            onPressed: handler,
            color: CupertinoColors.activeBlue,
          )
        : TextButton(
            child: Text(text, style: TextStyle(color: Colors.white, fontSize: 25,)),
            onPressed: handler,
            style: TextButton.styleFrom(
              elevation: 10,
              backgroundColor: Colors.cyan,
              padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10)
            ),
          );
  }
}

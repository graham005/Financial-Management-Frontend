import 'package:flutter/material.dart';
// ignore: must_be_immutable
class SelectableTextUtil extends StatelessWidget {
  String text;
  Color? color;
  double? size;
  bool? weight;
  SelectableTextUtil({super.key,required this.text,this.size,this.color,this.weight});

  @override
  Widget build(BuildContext context) {
    return  SelectableText(text,

      style: TextStyle(color:color??Colors.white,fontSize:size?? 16,
          fontWeight:weight==null?FontWeight.w600: FontWeight.w700
      ),);
  }
}
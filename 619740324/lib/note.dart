import 'package:flutter/material.dart';
import 'event.dart';

class Note {
  final List<Event> eventList = <Event>[];
  String eventName;
  CircleAvatar circleAvatar;
  String subTittleEvent;

  Note(this.eventName, this.circleAvatar, this.subTittleEvent);
}
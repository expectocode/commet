import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/permissions.dart';
import 'package:flutter/material.dart';

abstract class Space {
  late String identifier;
  late Client client;
  late ImageProvider? avatar = null;
  final Map<String, Room> _rooms = {};
  late List<Room> rooms = List.empty(growable: true);
  late Key key = UniqueKey();
  late Permissions permissions;

  late String displayName;
  int notificationCount = 0;

  Space(this.identifier, this.client);

  StreamController<void> onUpdate = StreamController.broadcast();

  late StreamController<int> onRoomAdded = StreamController.broadcast();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Space) return false;

    return identifier == other.identifier;
  }

  bool containsRoom(String identifier) {
    return _rooms.containsKey(identifier);
  }

  void addRoom(Room room) {
    if (!containsRoom(room.identifier)) {
      rooms.add(room);
      _rooms[room.identifier] = room;
      onRoomAdded.add(rooms.length - 1);
    }
  }

  void reorderRooms(int oldIndex, int newIndex) {
    onRoomReorderedCallback(oldIndex, newIndex);

    if (newIndex > oldIndex) {
      newIndex = newIndex - 1;
    }
    final item = rooms.removeAt(oldIndex);
    rooms.insert(newIndex, item);
  }

  void onRoomReorderedCallback(int oldIndex, int newIndex) {}

  Future<Room> createSpaceChild(String name, RoomVisibility visibility);
}

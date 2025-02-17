import 'dart:async';
import 'dart:typed_data';

import 'package:commet/client/components/component.dart';
import 'package:commet/client/invitation.dart';
import 'package:commet/client/room_preview.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/space.dart';
import 'package:flutter/material.dart';

import 'peer.dart';

export 'package:commet/client/room.dart';
export 'package:commet/client/space.dart';
export 'package:commet/client/peer.dart';
export 'package:commet/client/timeline.dart';

enum LoginType {
  loginPassword,
  token,
}

enum LoginResult { success, failed, error, alreadyLoggedIn }

abstract class Client {
  Future<LoginResult> login(
      LoginType type, String userIdentifier, String server,
      {String? password, String? token});

  /// Local identifier for this client instance
  String get identifier;

  /// The Peer owned by the current user session
  Peer? self;

  ValueKey get key => ValueKey(identifier);

  /// True if the client protocol supports End to End Encryption
  bool get supportsE2EE;

  /// Max size in bytes for uploaded files
  int? get maxFileSize;

  /// Gets a list of rooms which are direct messages between two users
  List<Room> get directMessages;

  /// Gets a list of rooms which do not belong to any spaces
  List<Room> get singleRooms;

  /// Gets list of all rooms
  List<Room> get rooms;

  /// Gets list of all spaces
  List<Space> get spaces;

  /// Gets list of all currently known users
  List<Peer> get peers;

  /// Gets a list of invitations to join other rooms or spaces
  List<Invitation> get invitations;

  /// When a room is added, this will be called with the index of the new room
  Stream<int> get onRoomAdded;

  /// When a space is added, this will be called with the index of the new space
  Stream<int> get onSpaceAdded;

  /// When a room is removed, this will be called with the index of the room which was removed
  Stream<int> get onRoomRemoved;

  /// When a space is removed, this will be called with the index of the space which was removed
  Stream<int> get onSpaceRemoved;

  /// When a new peer is found, this will be called with the index of the new peer
  Stream<int> get onPeerAdded;

  /// When the client receives an update from the server, this will be called
  Stream<void> get onSync;

  Future<void> init(bool loadingFromCache);

  /// Logout and invalidate the current session
  Future<void> logout();

  bool isLoggedIn();

  /// Returns true if the client is a member of the given space
  bool hasSpace(String identifier);

  /// Returns true if the client is a member of the given room
  bool hasRoom(String identifier);

  /// Returns true if the client knows of this peer
  bool hasPeer(String identifier);

  /// Gets a room by ID. only returns rooms which the client is a member of, otherwise null
  Room? getRoom(String identifier);

  /// Gets a space by ID. only returns spaces which the client is a member of, otherwise null
  Space? getSpace(String identifier);

  /// Gets a peer by ID. will return a peer object for any given ID and then load the data from the server.
  /// This is so that you can display any given peer without having to load the data for it
  Peer getPeer(String identifier);

  /// Create a new room
  Future<Room> createRoom(String name, RoomVisibility visibility,
      {bool enableE2EE = true});

  /// Create a new space
  Future<Space> createSpace(String name, RoomVisibility visibility);

  /// Join an existing space by address
  Future<Space> joinSpace(String address);

  /// Join an existing room by address
  Future<Room> joinRoom(String address);

  /// Leaves a room
  Future<void> leaveRoom(Room room);

  /// Leaves a space
  Future<void> leaveSpace(Space space);

  /// Queries the server for information about a space which this client is not a member of
  Future<RoomPreview?> getSpacePreview(String address);

  /// Queries the server for information about a room which this client is not a member of
  Future<RoomPreview?> getRoomPreview(String address);

  /// Update the current user avatar
  Future<void> setAvatar(Uint8List bytes, String mimeType);

  /// Set the display name of the current user
  Future<void> setDisplayName(String name);

  /// End the current session and prepare for disposal
  Future<void> close();

  /// Find all the rooms which could be added to a given space
  Iterable<Room> getEligibleRoomsForSpace(Space space);

  /// Build a widget for display in the developer options debug menu
  Widget buildDebugInfo();

  /// Open a new direct message with another user
  Future<Room?> createDirectMessage(String userId);

  /// Accept an invitation to join a room or space which this client is not yet a member of
  Future<void> acceptInvitation(Invitation invitation);

  /// Reject an invitation to join a room or space which this client is not yet a member of
  Future<void> rejectInvitation(Invitation invitation);

  T? getComponent<T extends Component>();
}

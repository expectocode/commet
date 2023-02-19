import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/utils/rng.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:path_provider/path_provider.dart';

import 'matrix_room.dart';
import 'matrix_space.dart';

class MatrixClient extends Client {
  @override
  late StreamController<void> onSync = StreamController.broadcast();

  late matrix.Client _matrixClient;

  MatrixClient() : super(RandomUtils.getRandomString(20)) {
    log("Creating matrix client");
    _matrixClient = matrix.Client(
      'Commet',
      databaseBuilder: (_) async {
        final dir = await getApplicationSupportDirectory();
        final db = matrix.HiveCollectionsDatabase('matrix_commet.', dir.path);
        await db.open();
        return db;
      },
    );

    _matrixClient.onSync.stream
        .listen((event) => {log("On Sync Happened?"), onSync.add(null), _updateRoomslist(), _updateSpacesList()});

    log("Done!");
  }

  void log(String s) {
    print('Matrix Client] $s');
  }

  @override
  Future<void> init() async {
    log("Initialising client");
    var result = await _matrixClient.init();
    _updateRoomslist();
    _updateSpacesList();

    if (_matrixClient.userID != null) user = MatrixPeer(_matrixClient, _matrixClient.userID!);

    return result;
  }

  @override
  bool isLoggedIn() => _matrixClient.isLogged();

  @override
  Future<LoginResult> login(LoginType type, String userIdentifier, String server,
      {String? password, String? token}) async {
    LoginResult loginResult = LoginResult.error;

    log("Attempting to log in!");

    switch (type) {
      case LoginType.loginPassword:
        await _matrixClient.checkHomeserver((Uri.https((server))));
        var result = await _matrixClient.login(matrix.LoginType.mLoginPassword,
            password: password, identifier: matrix.AuthenticationUserIdentifier(user: userIdentifier));

        loginResult = LoginResult.success;

        break;
      case LoginType.token:
        // TODO: Handle this case.
        break;
    }

    switch (loginResult) {
      case LoginResult.success:
        log("Login success!");
        _postLoginSuccess();
        break;
    }

    return loginResult;
  }

  @override
  Future<void> logout() {
    return _matrixClient.logout();
  }

  void _postLoginSuccess() {
    _updateRoomslist();

    print(_matrixClient.accountData.keys);
  }

  void _updateRoomslist() {
    var allRooms = _matrixClient.rooms.where((element) => !element.isSpace);

    for (var room in allRooms) {
      if (roomExists(room.id)) continue;

      addRoom(MatrixRoom(this, room, _matrixClient));
    }
  }

  void _updateSpacesList() {
    var allSpaces = _matrixClient.rooms.where((element) => element.isSpace);

    for (var space in allSpaces) {
      if (spaceExists(space.id)) continue;

      addSpace(MatrixSpace(this, space, _matrixClient));
    }
  }
}

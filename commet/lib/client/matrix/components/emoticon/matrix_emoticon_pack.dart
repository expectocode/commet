import 'dart:typed_data';

import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_room_emoticon_component.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';

class MatrixEmoticonPack implements EmoticonPack {
  late final MatrixEmoticonComponent component;
  String stateKey;

  @override
  final NotifyingList<MatrixEmoticon> emotes =
      NotifyingList.empty(growable: true);

  @override
  late String displayName;

  @override
  ImageProvider? image;

  @override
  IconData? icon;

  MatrixEmoticonPack(
    this.component,
    this.stateKey,
    Map<String, dynamic> initialState,
  ) {
    var info = initialState['pack'];
    displayName = info?['display_name'] ?? component.getDefaultDisplayName();

    if (info?['avatar_url'] != null) {
      try {
        var uri = Uri.parse(info!['avatar_url']!);
        image = MatrixMxcImage(uri, component.client.getMatrixClient());
      } catch (_) {}
    }

    image ??= component.getDefaultImage();
    icon = component.getDefaultIcon();

    var images = initialState['images'] as Map<String, dynamic>?;
    if (images == null) return;

    bool isStickerPackCache = isStickerPack;
    bool isEmojiPackCache = isEmojiPack;

    for (var image in images.keys) {
      var url = images[image]['url'];

      var usages = images[image]['usage'] as List?;

      bool markedSticker = false;
      bool markedEmoji = false;
      if (usages != null) {
        markedSticker = usages.contains("sticker");
        markedEmoji = usages.contains("emoticon");
      }

      if (url != null) {
        var uri = Uri.parse(url);
        emotes.add(MatrixEmoticon(uri, component.client.getMatrixClient(),
            shortcode: image,
            isEmojiPack: isEmojiPackCache,
            isStickerPack: isStickerPackCache,
            isMarkedEmoji: markedEmoji,
            isMarkedSticker: markedSticker));
      }
    }
  }

  @override
  Future<void> addEmoticon(
      {required String slug,
      String? shortcode,
      required Uint8List data,
      String? mimeType,
      bool? isEmoji,
      bool? isSticker}) async {
    var result = await component.createEmoticon(identifier, shortcode!, data);
    if (result == null) return;

    var url = result['images'][shortcode]['url'];

    try {
      var uri = Uri.parse(url);
      var emote = MatrixEmoticon(uri, component.client.getMatrixClient(),
          shortcode: shortcode);
      emotes.add(emote);
    } catch (_) {}
  }

  List? _getUsage() {
    var info = component.getState(identifier)['pack'] as Map<String, dynamic>?;
    if (info == null) return null;

    var usage = info.tryGet("usage") as List?;
    return usage;
  }

  @override
  String get attribution => "";

  @override
  Future<void> deleteEmoticon(Emoticon emoticon) async {
    await component.deleteEmoticon(identifier, emoticon.shortcode!);
    emotes.remove(emoticon);
  }

  @override
  List<Emoticon> get emoji =>
      emotes.where((element) => element.isEmoji).toList();

  @override
  List<Emoticon> get stickers =>
      emotes.where((element) => element.isSticker).toList();

  @override
  String get identifier => stateKey;

  @override
  bool get isEmojiPack => _getUsage()?.contains("emoticon") ?? true;

  @override
  bool get isGloballyAvailable => component.isGloballyAvailable(identifier);

  @override
  bool get isStickerPack => _getUsage()?.contains("sticker") ?? true;

  @override
  Future<void> markAsGlobal(bool isGlobal) async {
    if (component is MatrixRoomEmoticonComponent) {
      await (component as MatrixRoomEmoticonComponent)
          .markAsGlobal(isGlobal, identifier);
    }
  }

  @override
  Future<void> markAsEmoji(bool isEmojiPack) async {
    await component.setPackUsages(identifier,
        [if (isEmojiPack) 'emoticon', if (isStickerPack) 'sticker']);

    for (var emote in emotes) {
      emote.markPackAsEmoji(isEmojiPack);
    }
  }

  @override
  Future<void> markAsSticker(bool isStickerPack) async {
    await component.setPackUsages(identifier,
        [if (isEmojiPack) 'emoticon', if (isStickerPack) 'sticker']);

    for (var emote in emotes) {
      emote.markPackAsSticker(isStickerPack);
    }
  }

  @override
  Future<void> markEmoticonAsEmoji(Emoticon emoticon, bool isEmoji) async {
    await component.setEmoticonUsages(identifier, emoticon.shortcode!,
        [if (isEmoji) 'emoticon', if (emoticon.isMarkedSticker) 'sticker']);

    (emoticon as MatrixEmoticon).markAsEmoji(isEmoji);
  }

  @override
  Future<void> markEmoticonAsSticker(Emoticon emoticon, bool isSticker) async {
    await component.setEmoticonUsages(identifier, emoticon.shortcode!,
        [if (emoticon.isMarkedEmoji) 'emoticon', if (isSticker) 'sticker']);

    (emoticon as MatrixEmoticon).markAsSticker(isSticker);
  }

  @override
  Stream<int> get onEmoticonAdded => emotes.onAdd;

  @override
  Future<void> renameEmoticon(Emoticon emoticon, String name) {
    return component.renameEmoticon(identifier, emoticon.shortcode!, name);
  }
}

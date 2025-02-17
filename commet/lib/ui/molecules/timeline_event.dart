import 'package:commet/config/build_config.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/generic_room_event.dart';
import 'package:commet/ui/molecules/message.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/atoms/icon_button.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../client/client.dart';
import '../../client/components/emoticon/emoticon.dart';
import '../atoms/message_attachment.dart';
import '../atoms/tooltip.dart' as t;

class TimelineEventView extends StatefulWidget {
  const TimelineEventView(
      {required this.event,
      required this.timeline,
      super.key,
      this.onDelete,
      this.hovered = false,
      this.showSender = true,
      this.setReplyingEvent,
      this.setEditingEvent,
      this.onDoubleTap,
      this.onReactionTapped,
      this.onLongPress,
      this.deleteEvent,
      this.canDeleteEvent = false,
      this.useCachedFormat = false,
      this.debugInfo});
  final TimelineEvent event;
  final bool hovered;
  final Function? onDelete;
  final bool showSender;
  final String? debugInfo;
  final Timeline timeline;
  final bool useCachedFormat;
  final Function()? onDoubleTap;
  final Function()? onLongPress;
  final Function()? setReplyingEvent;
  final Function()? setEditingEvent;
  final Function()? deleteEvent;
  final bool canDeleteEvent;
  final Function(Emoticon emote)? onReactionTapped;

  @override
  State<TimelineEventView> createState() => _TimelineEventState();
}

class _TimelineEventState extends State<TimelineEventView> {
  TimelineEvent? relatedEvent;

  String messagePlaceholderSticker(String user) =>
      Intl.message("$user sent a sticker",
          desc: "Message body for when a user sends a sticker",
          args: [user],
          name: "messagePlaceholderSticker");

  String get messageFailedToDecrypt => Intl.message("Failed to decrypt event",
      desc: "Placeholde text for when a message fails to decrypt",
      name: "messageFailedToDecrypt");

  String messagePlaceholderUserCreatedRoom(String user) =>
      Intl.message("$user created the room!",
          desc: "Message body for when a user created the room",
          args: [user],
          name: "messagePlaceholderUserCreatedRoom");

  String messagePlaceholderUserJoinedRoom(String user) =>
      Intl.message("$user joined the room!",
          desc: "Message body for when a user joins the room",
          args: [user],
          name: "messagePlaceholderUserJoinedRoom");

  String messagePlaceholderUserLeftRoom(String user) =>
      Intl.message("$user left the room",
          desc: "Message body for when a user leaves the room",
          args: [user],
          name: "messagePlaceholderUserLeftRoom");

  String messagePlaceholderUserUpdatedAvatar(String user) =>
      Intl.message("$user updated their avatar",
          desc: "Message body for when a user updates their avatar",
          args: [user],
          name: "messagePlaceholderUserUpdatedAvatar");

  String messagePlaceholderUserUpdatedName(String user) =>
      Intl.message("$user updated their display name",
          desc: "Message body for when a user updates their display name",
          args: [user],
          name: "messagePlaceholderUserUpdatedName");

  String messagePlaceholderUserInvited(String sender, String invitedUser) =>
      Intl.message("$sender invited $invitedUser",
          desc: "Message body for when a user invites another user to the room",
          args: [sender, invitedUser],
          name: "messagePlaceholderUserInvited");

  String messagePlaceholderUserRejectedInvite(String user) =>
      Intl.message("$user rejected the invitation",
          desc: "Message body for when a user rejected an invitation to a room",
          args: [user],
          name: "messagePlaceholderUserRejectedInvite");

  String get errorMessageFailedToSend => Intl.message("Failed to send",
      desc:
          "Text that is placed below a message when the message fails to send",
      name: "errorMessageFailedToSend");

  @override
  void initState() {
    if (widget.event.relatedEventId != null) {
      relatedEvent = widget.timeline.tryGetEvent(widget.event.relatedEventId!);
      if (relatedEvent == null) {
        fetchRelatedEvent();
      }
    }

    widget.timeline.client.getPeer(widget.event.senderId).loading?.then((_) {
      if (mounted) setState(() {});
    });

    super.initState();
  }

  void fetchRelatedEvent() async {
    var event =
        await widget.timeline.fetchEventById(widget.event.relatedEventId!);
    if (mounted)
      setState(() {
        relatedEvent = event;
      });
  }

  @override
  Widget build(BuildContext context) {
    var display = eventToWidget(widget.event);
    return AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: widget.hovered ? m.Colors.red : m.Colors.transparent,
        child: Opacity(
          opacity: [TimelineEventStatus.sending, TimelineEventStatus.error]
                  .contains(widget.event.status)
              ? 0.5
              : 1,
          child: display,
        ));
  }

  String get displayName =>
      widget.timeline.room.client.getPeer(widget.event.senderId).displayName;

  ImageProvider? get avatar =>
      widget.timeline.room.client.getPeer(widget.event.senderId).avatar;

  Color get color => widget.timeline.room.getColorOfUser(widget.event.senderId);

  Color get replyColor => relatedEvent == null
      ? m.Theme.of(context).colorScheme.onPrimary
      : widget.timeline.room.getColorOfUser(relatedEvent!.senderId);

  String? get relatedEventDisplayName => relatedEvent == null
      ? null
      : widget.timeline.client.getPeer(relatedEvent!.senderId).displayName;

  Widget? eventToWidget(TimelineEvent event) {
    if (event.status == TimelineEventStatus.removed) return const SizedBox();
    switch (widget.event.type) {
      case EventType.message:
      case EventType.sticker:
        return Message(
          senderName: displayName,
          senderColor: color,
          senderAvatar: avatar,
          sentTimeStamp: widget.event.originServerTs,
          onDoubleTap: widget.onDoubleTap,
          onLongPress: widget.onLongPress,
          showSender: widget.showSender,
          reactions: widget.event.reactions,
          currentUserIdentifier: widget.timeline.room.client.self!.identifier,
          replyBody: relatedEvent?.body ??
              (relatedEvent?.type == EventType.sticker
                  ? messagePlaceholderSticker(displayName)
                  : null),
          replySenderName: relatedEventDisplayName,
          replySenderColor: replyColor,
          isInReply: widget.event.relatedEventId != null,
          edited: widget.event.edited,
          onReactionTapped: widget.onReactionTapped,
          body: buildBody(),
          child: event.status == TimelineEventStatus.error
              ? tiamat.Text.error(errorMessageFailedToSend)
              : null,
        );
      case EventType.encrypted:
        return Message(
            senderName: displayName,
            senderColor: color,
            senderAvatar: avatar,
            showSender: widget.showSender,
            body: tiamat.Text.error(messageFailedToDecrypt),
            currentUserIdentifier: widget.timeline.room.client.self!.identifier,
            sentTimeStamp: widget.event.originServerTs);
      case EventType.roomCreated:
        return GenericRoomEvent(messagePlaceholderUserCreatedRoom(displayName),
            m.Icons.room_preferences_outlined);
      case EventType.memberJoined:
        return GenericRoomEvent(messagePlaceholderUserJoinedRoom(displayName),
            m.Icons.waving_hand_rounded);
      case EventType.memberLeft:
        return GenericRoomEvent(messagePlaceholderUserLeftRoom(displayName),
            m.Icons.subdirectory_arrow_left_rounded);
      case EventType.memberAvatar:
        return GenericRoomEvent(
            messagePlaceholderUserUpdatedAvatar(displayName), m.Icons.person);
      case EventType.memberDisplayName:
        return GenericRoomEvent(
            messagePlaceholderUserUpdatedName(displayName), m.Icons.edit);
      case EventType.memberInvited:
        return GenericRoomEvent(
            messagePlaceholderUserInvited(displayName, event.stateKey!),
            m.Icons.person_add);
      case EventType.memberInvitationRejected:
        return GenericRoomEvent(
            messagePlaceholderUserRejectedInvite(displayName),
            m.Icons.subdirectory_arrow_left_rounded);
      default:
        break;
    }

    if (BuildConfig.DEBUG && preferences.developerMode) {
      return m.Padding(
        padding: const EdgeInsets.all(8.0),
        child: Placeholder(
            child: event.source != null
                ? tiamat.Text.tiny(event.source!)
                : const Placeholder(
                    fallbackHeight: 20,
                  )),
      );
    }
    return null;
  }

  Widget buildMenuEntry(IconData icon, String label, Function()? callback) {
    const double size = 32;
    return t.Tooltip(
      text: label,
      child: m.Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: m.SizedBox(
          width: size,
          height: size,
          child: IconButton(
            size: 20,
            icon: icon,
            onPressed: () => callback?.call(),
          ),
        ),
      ),
    );
  }

  bool canUserEditEvent() {
    return widget.timeline.room.permissions.canUserEditMessages &&
        widget.event.senderId == widget.timeline.room.client.self!.identifier;
  }

  Widget buildBody() {
    switch (widget.event.type) {
      case EventType.message:
        return buildMessageBody();
      case EventType.sticker:
        return buildStickerBody();
      default:
        return const Placeholder(
          fallbackHeight: 50,
        );
    }
  }

  Widget buildMessageBody() {
    return m.Material(
      color: m.Colors.transparent,
      child: Column(
        children: [
          buildMessageText(),
          if (widget.event.attachments != null) buildMessageAttachments()
        ],
      ),
    );
  }

  Widget buildMessageAttachments() {
    return Wrap(
      children: widget.event.attachments!
          .map((e) => Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                child: MessageAttachment(
                  e,
                ),
              ))
          .toList(),
    );
  }

  Widget buildMessageText() {
    const bool selectableText = BuildConfig.DESKTOP || BuildConfig.WEB;

    if (widget.event.bodyFormat != null) {
      var formatted = widget.useCachedFormat
          ? widget.event.formattedContent
          : widget.event.buildFormattedContent();

      // if the cache didnt have anything lets just build new content. This should really never happen though
      formatted ??= widget.event.buildFormattedContent();

      return selectableText ? m.SelectionArea(child: formatted) : formatted;
    }

    if (widget.event.body != null)
      return selectableText
          ? m.SelectionArea(child: tiamat.Text.body(widget.event.body!))
          : tiamat.Text.body(widget.event.body!);

    return const SizedBox();
  }

  Widget buildStickerBody() {
    return m.Material(
      color: m.Colors.transparent,
      child: Column(
        children: [
          if (widget.event.attachments != null)
            Wrap(
              children: widget.event.attachments!
                  .map((e) => Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                        child: MessageAttachment(
                          e,
                          ignorePointer: widget.event.type == EventType.sticker,
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

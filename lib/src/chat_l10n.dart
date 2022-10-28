import 'package:flutter/material.dart';

/// Base chat l10n containing all required properties to provide localized copy.
/// Extend this class if you want to create a custom l10n.
@immutable
abstract class ChatL10n {
  /// Creates a new chat l10n based on provided copy
  const ChatL10n({
    required this.attachmentButtonAccessibilityLabel,
    required this.emptyChatPlaceholder,
    required this.fileButtonAccessibilityLabel,
    required this.inputPlaceholder,
    required this.sendButtonAccessibilityLabel,
    required this.audioButtonAccessibilityLabel,
    required this.today,
    required this.yesterday,
    required this.playButtonAccessibilityLabel,
    required this.pauseButtonAccessibilityLabel,
    required this.audioTrackAccessibilityLabel,
  });

  /// Accessibility label (hint) for the attachment button
  final String attachmentButtonAccessibilityLabel;

  /// Placeholder when there are no messages
  final String emptyChatPlaceholder;

  /// Accessibility label (hint) for the tap action on file message
  final String fileButtonAccessibilityLabel;

  /// Accessibility label (hint) for the tap action on audio message when playing
  final String pauseButtonAccessibilityLabel;

  /// Accessibility label (hint) for the tap action on audio message when not playing
  final String playButtonAccessibilityLabel;

  /// Placeholder for the text field
  final String inputPlaceholder;

  /// Accessibility label (hint) for the send button
  final String sendButtonAccessibilityLabel;

  /// Accessibility label (hint) for the audio button
  final String audioButtonAccessibilityLabel;

  /// Today string
  final String today;

  /// Yesterday string
  final String yesterday;

  /// Accessibility label (hint) for the audio track
  final String audioTrackAccessibilityLabel;
}

/// English l10n which extends [ChatL10n]
@immutable
class ChatL10nEn extends ChatL10n {
  /// Creates English l10n. Use this constructor if you want to
  /// override only a couple of properties, otherwise create a new class
  /// which extends [ChatL10n]
  const ChatL10nEn({
    String attachmentButtonAccessibilityLabel = 'Send media',
    String emptyChatPlaceholder = 'No messages here yet',
    String fileButtonAccessibilityLabel = 'File',
    String inputPlaceholder = 'Message',
    String sendButtonAccessibilityLabel = 'Send',
    String today = 'Today',
    String yesterday = 'Yesterday',
    String audioButtonAccessibilityLabel = 'Record audio message',
    String playButtonAccessibilityLabel = 'Play',
    String pauseButtonAccessibilityLabel = 'Pause',
    String audioTrackAccessibilityLabel = 'Tap to play/pause, slide to seek',
  }) : super(
          attachmentButtonAccessibilityLabel:
              attachmentButtonAccessibilityLabel,
          emptyChatPlaceholder: emptyChatPlaceholder,
          fileButtonAccessibilityLabel: fileButtonAccessibilityLabel,
          inputPlaceholder: inputPlaceholder,
          sendButtonAccessibilityLabel: sendButtonAccessibilityLabel,
          today: today,
          yesterday: yesterday,
          audioButtonAccessibilityLabel: audioButtonAccessibilityLabel,
          playButtonAccessibilityLabel: playButtonAccessibilityLabel,
          pauseButtonAccessibilityLabel: pauseButtonAccessibilityLabel,
          audioTrackAccessibilityLabel: audioTrackAccessibilityLabel,
        );
}

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import '../models/send_button_visibility_mode.dart';
import 'package:flutter_chat_ui/src/widgets/audio_button.dart';
import 'attachment_button.dart';
import 'audio_recorder.dart';
import 'inherited_chat_theme.dart';
import 'inherited_l10n.dart';
import 'send_button.dart';

class NewLineIntent extends Intent {
  const NewLineIntent();
}

class SendMessageIntent extends Intent {
  const SendMessageIntent();
}

/// A class that represents bottom bar widget with a text field, attachment and
/// send buttons inside. By default hides send button when text field is empty.
class Input extends StatefulWidget {
  /// Creates [Input] widget
  const Input({
    Key? key,
    this.isAttachmentUploading,
    this.onAttachmentPressed,
    required this.onSendPressed,
    this.onTextChanged,
    this.onTextFieldTap,
    required this.sendButtonVisibilityMode,
    this.onAudioRecorded,
  }) : super(key: key);

  /// See [AttachmentButton.onPressed]
  final void Function()? onAttachmentPressed;

  /// Whether attachment is uploading. Will replace attachment button with a
  /// [CircularProgressIndicator]. Since we don't have libraries for
  /// managing media in dependencies we have no way of knowing if
  /// something is uploading so you need to set this manually.
  final bool? isAttachmentUploading;

  /// Will be called on [SendButton] tap. Has [types.PartialText] which can
  /// be transformed to [types.TextMessage] and added to the messages list.
  final void Function(types.PartialText) onSendPressed;

  /// Will be called whenever the text inside [TextField] changes
  final void Function(String)? onTextChanged;

  /// Will be called on [TextField] tap
  final void Function()? onTextFieldTap;

  /// Controls the visibility behavior of the [SendButton] based on the
  /// [TextField] state inside the [Input] widget.
  /// Defaults to [SendButtonVisibilityMode.editing].
  final SendButtonVisibilityMode sendButtonVisibilityMode;

  /// See [AudioButton.onPressed]
  final Future<bool> Function({
    required Duration length,
    required String filePath,
    required List<double> waveForm,
    required String mimeType,
  })? onAudioRecorded;

  @override
  _InputState createState() => _InputState();
}

/// [Input] widget state
class _InputState extends State<Input> {
  final _inputFocusNode = FocusNode();
  final _audioRecorderKey = GlobalKey<AudioRecorderState>();
  final _textController = TextEditingController();
  bool _sendButtonVisible = false;
  bool _recordingAudio = false;
  bool _audioUploading = false;

  @override
  void initState() {
    super.initState();

    _handleSendButtonVisibilityModeChange();
  }

  @override
  void didUpdateWidget(covariant Input oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sendButtonVisibilityMode != oldWidget.sendButtonVisibilityMode) {
      _handleSendButtonVisibilityModeChange();
    }
  }

  @override
  void dispose() {
    _inputFocusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  Widget _audioWidget() {
    if (_audioUploading == true) {
      return SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          backgroundColor: Colors.transparent,
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            InheritedChatTheme.of(context).theme.inputTextColor,
          ),
        ),
      );
    } else {
      return AudioButton(
        onPressed: _toggleRecording,
        recordingAudio: _recordingAudio,
      );
    }
  }

  Future<void> _toggleRecording() async {
    if (!_recordingAudio) {
      setState(() {
        _recordingAudio = true;
      });
    } else {
      final audioRecording =
          await _audioRecorderKey.currentState!.stopRecording();
      if (audioRecording != null) {
        setState(() {
          _audioUploading = true;
        });
        final success = await widget.onAudioRecorded!(
          length: audioRecording.duration,
          filePath: audioRecording.filePath,
          waveForm: audioRecording.decibelLevels,
          mimeType: audioRecording.mimeType,
        );
        setState(() {
          _audioUploading = false;
        });
        if (success) {
          setState(() {
            _recordingAudio = false;
          });
        }
      }
    }
  }

  void _cancelRecording() async {
    setState(() {
      _recordingAudio = false;
    });
  }

  void _handleNewLine() {
    final _newValue = '${_textController.text}\r\n';
    _textController.value = TextEditingValue(
      text: _newValue,
      selection: TextSelection.fromPosition(
        TextPosition(offset: _newValue.length),
      ),
    );
  }

  void _handleSendButtonVisibilityModeChange() {
    _textController.removeListener(_handleTextControllerChange);
    if (widget.sendButtonVisibilityMode == SendButtonVisibilityMode.hidden) {
      _sendButtonVisible = false;
    } else if (widget.sendButtonVisibilityMode ==
        SendButtonVisibilityMode.editing) {
      _sendButtonVisible = _textController.text.trim() != '';
      _textController.addListener(_handleTextControllerChange);
    } else {
      _sendButtonVisible = true;
    }
  }

  void _handleSendPressed() {
    final trimmedText = _textController.text.trim();
    if (trimmedText != '') {
      final _partialText = types.PartialText(text: trimmedText);
      widget.onSendPressed(_partialText);
      _textController.clear();
    }
  }

  void _handleTextControllerChange() {
    setState(() {
      _sendButtonVisible = _textController.text.trim() != '';
    });
  }

  Widget _inputBuilder() {
    final _query = MediaQuery.of(context);
    final _buttonPadding = InheritedChatTheme.of(context)
        .theme
        .inputPadding
        .copyWith(left: 16, right: 16);
    final _safeAreaInsets = kIsWeb
        ? EdgeInsets.zero
        : EdgeInsets.fromLTRB(
            _query.padding.left,
            0,
            _query.padding.right,
            _query.viewInsets.bottom + _query.padding.bottom,
          );
    final _textPadding = InheritedChatTheme.of(context)
        .theme
        .inputPadding
        .copyWith(left: 0, right: 0)
        .add(
          EdgeInsetsDirectional.fromSTEB(
            widget.onAttachmentPressed != null ? 0 : 24,
            0,
            _sendButtonVisible ? 0 : 24,
            0,
          ),
        );

    return Focus(
      autofocus: true,
      child: Padding(
        padding: InheritedChatTheme.of(context).theme.inputMargin,
        child: Material(
          borderRadius: InheritedChatTheme.of(context).theme.inputBorderRadius,
          color: InheritedChatTheme.of(context).theme.inputBackgroundColor,
          child: Container(
            decoration:
                InheritedChatTheme.of(context).theme.inputContainerDecoration,
            padding: _safeAreaInsets,
            child: Row(
              children: [
                if (widget.onAttachmentPressed != null && !_recordingAudio)
                  AttachmentButton(
                    isLoading: widget.isAttachmentUploading ?? false,
                    onPressed: widget.onAttachmentPressed,
                    padding: _buttonPadding,
                  ),
                Expanded(
                  child: Padding(
                    padding: _textPadding,
                    child: _recordingAudio
                        ? AudioRecorder(
                            key: _audioRecorderKey,
                            onCancelRecording: _cancelRecording,
                            disabled: _audioUploading,
                          )
                        : TextField(
                            controller: _textController,
                            cursorColor: InheritedChatTheme.of(context)
                                .theme
                                .inputTextCursorColor,
                            decoration: InheritedChatTheme.of(context)
                                .theme
                                .inputTextDecoration
                                .copyWith(
                                  hintStyle: InheritedChatTheme.of(context)
                                      .theme
                                      .inputTextStyle
                                      .copyWith(
                                        color: InheritedChatTheme.of(context)
                                            .theme
                                            .inputTextColor
                                            .withOpacity(0.5),
                                      ),
                                  hintText: InheritedL10n.of(context)
                                      .l10n
                                      .inputPlaceholder,
                                ),
                            focusNode: _inputFocusNode,
                            keyboardType: TextInputType.multiline,
                            maxLines: 5,
                            minLines: 1,
                            onChanged: widget.onTextChanged,
                            onTap: widget.onTextFieldTap,
                            style: InheritedChatTheme.of(context)
                                .theme
                                .inputTextStyle
                                .copyWith(
                                  color: InheritedChatTheme.of(context)
                                      .theme
                                      .inputTextColor,
                                ),
                            textCapitalization: TextCapitalization.sentences,
                          ),
                  ),
                ),
                Visibility(
                  visible: _sendButtonVisible,
                  child: SendButton(
                    onPressed: _handleSendPressed,
                    padding: _buttonPadding,
                  ),
                ),
                Visibility(
                  visible:
                      widget.onAudioRecorded != null && !_sendButtonVisible,
                  child: _audioWidget(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return GestureDetector(
      onTap: () => _inputFocusNode.requestFocus(),
      child: isAndroid || isIOS
          ? _inputBuilder()
          : Shortcuts(
              shortcuts: {
                LogicalKeySet(LogicalKeyboardKey.enter):
                    const SendMessageIntent(),
                LogicalKeySet(LogicalKeyboardKey.enter, LogicalKeyboardKey.alt):
                    const NewLineIntent(),
                LogicalKeySet(
                        LogicalKeyboardKey.enter, LogicalKeyboardKey.shift):
                    const NewLineIntent(),
              },
              child: Actions(
                actions: {
                  SendMessageIntent: CallbackAction<SendMessageIntent>(
                    onInvoke: (SendMessageIntent intent) =>
                        _handleSendPressed(),
                  ),
                  NewLineIntent: CallbackAction<NewLineIntent>(
                    onInvoke: (NewLineIntent intent) => _handleNewLine(),
                  ),
                },
                child: _inputBuilder(),
              ),
            ),
    );
  }
}

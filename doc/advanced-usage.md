---
id: advanced-usage
title: Advanced Usage
---

We didn't add any dependencies for working with files and images, since there are a couple of them and you might want to use different ones.

## Images

In this example, we will use [image_picker](https://pub.dev/packages/image_picker), follow the instructions there to install it. After it is done we can use the image picker to select an image and send it as a message (full example with images and files can be found [here](#putting-it-all-together)):

```dart
// ...
import 'package:image_picker/image_picker.dart';

class _MyHomePageState extends State<MyHomePage> {
  // ...
  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = types.ImageMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: randomString(),
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );

      _addMessage(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Chat(
        // ...
        onAttachmentPressed: _handleImageSelection,
      ),
    );
  }
}
```

Similar to the text message, you will need to create an image message using data from the image picker. In this example, we use local path just for demo purposes, but for the backend service, you will upload the image first and then send the received URL using the `uri` property.

To keep the UI clean, the image message renders in two different ways, if the aspect ratio is too low or too high it renders like a file message, so you don't see a narrow line on the UI. The second way is a classic image in the chat. Go give it a try.

:::tip

You can use this URL https://bit.ly/2P0cn2g to test the file message presentation, remove height and width from the `message` so the library will calculate it automatically and replace `uri`'s data with this URL.

:::

On tap, images will be previewed inside an interactive image gallery. To disable the image gallery pass `disableImageGallery` property to the `Chat` widget.

## Files

In this example, we will use [file_picker](https://pub.dev/packages/file_picker), follow the instructions there to install it. After it is done we can use the file picker to select a file and send it as a message (full example with images and files can be found [here](#putting-it-all-together)):

```dart
// ...
import 'package:file_picker/file_picker.dart';

class _MyHomePageState extends State<MyHomePage> {
  // ...
  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final message = types.FileMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: randomString(),
        name: result.files.single.name,
        size: result.files.single.size,
        uri: result.files.single.path!,
      );

      _addMessage(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Chat(
        // ...
        onAttachmentPressed: _handleFileSelection,
      ),
    );
  }
}
```

Similar to the text message, you will need to create a file message using data from the document picker. In this example, `uri` will point to the local filesystem just for demo purposes, but for the backend service, you will upload the file first and then send the received URL using the `uri` property.

### Opening a file

Right now, nothing will happen when a user taps on a file message, we will need to add another dependency. In this case, let's add [open_file](https://pub.dev/packages/open_file). As usual, follow the instructions there to install it. Now we can open a file:

```dart
// ...
import 'package:open_file/open_file.dart';

class _MyHomePageState extends State<MyHomePage> {
  // ...
  void _handleMessageTap(BuildContext context, types.Message message) async {
    if (message is types.FileMessage) {
      await OpenFile.open(message.uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Chat(
        // ...
        onMessageTap: _handleMessageTap,
      ),
    );
  }
}
```

## Link preview

Link preview works automatically, we created a separate package for that, you can found it [here](https://pub.dev/packages/flutter_link_previewer). It can be disabled by setting `usePreviewData` to false. Usually, however, you'll want to save the preview data so it stays the same, you can do that using `onPreviewDataFetched` callback:

```dart
class _MyHomePageState extends State<MyHomePage> {
  // ...
  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = _messages[index].copyWith(previewData: previewData);

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      setState(() {
        _messages[index] = updatedMessage;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Chat(
        // ...
        onPreviewDataFetched: _handlePreviewDataFetched,
      ),
    );
  }
}
```

## Putting it all together

Now to choose between images and files from a single button we will use `showModalBottomSheet`. If you skipped previous sections and want to use this example, remember to install - [image_picker](https://pub.dev/packages/image_picker), [file_picker](https://pub.dev/packages/file_picker) and [open_file](https://pub.dev/packages/open_file). This is a drop-in example, everything should work if you had installed all the dependencies.

```dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';

// For the testing purposes, you should probably use https://pub.dev/packages/uuid
String randomString() {
  var random = Random.secure();
  var values = List<int>.generate(16, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<types.Message> _messages = [];
  final _user = const types.User(id: '06c33e8b-e835-4736-80f4-63f44b66666c');

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleAtachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: SizedBox(
            height: 144,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleImageSelection();
                  },
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Photo'),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleFileSelection();
                  },
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('File'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final message = types.FileMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: randomString(),
        name: result.files.single.name,
        size: result.files.single.size,
        uri: result.files.single.path!,
      );

      _addMessage(message);
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = types.ImageMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: randomString(),
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );

      _addMessage(message);
    }
  }

  void _handleMessageTap(BuildContext context, types.Message message) async {
    if (message is types.FileMessage) {
      await OpenFile.open(message.uri);
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = _messages[index].copyWith(previewData: previewData);

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      setState(() {
        _messages[index] = updatedMessage;
      });
    });
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: randomString(),
      text: message.text,
    );

    _addMessage(textMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Chat(
        messages: _messages,
        onAttachmentPressed: _handleAtachmentPressed,
        onMessageTap: _handleMessageTap,
        onPreviewDataFetched: _handlePreviewDataFetched,
        onSendPressed: _handleSendPressed,
        user: _user,
      ),
    );
  }
}
```

## Custom chat bubbles

Let's use the [bubble](https://pub.dev/packages/bubble) package as an example (version `1.2.1` at the point of writing, example might not work as it is if the new version is released). Just pass the `_bubbleBuilder` function to the `Chat` widget. `child` parameter of the `_bubbleBuilder` function is a default message content (which you can further customize using `customMessageBuilder`, `fileMessageBuilder`, `imageMessageBuilder`, `textMessageBuilder` etc.). `message` parameter gives you the actual message to work with, where you can see whether the current user is author, message type, or anything you'd like to customize the bubble. `nextMessageInGroup` parameter gives you a hint about message groups and if you want to add a nip only for the last message in the group, you can do that (messages are grouped when written in quick succession by the same author).

```dart
import 'package:bubble/bubble.dart';

Widget _bubbleBuilder(
  Widget child, {
  required message,
  required nextMessageInGroup,
}) {
  return Bubble(
    child: child,
    color: _user.id != message.author.id ||
            message.type == types.MessageType.image
        ? const Color(0xfff5f5f7)
        : const Color(0xff6f61e8),
    margin: nextMessageInGroup
        ? const BubbleEdges.symmetric(horizontal: 6)
        : null,
    nip: nextMessageInGroup
        ? BubbleNip.no
        : _user.id != message.author.id
            ? BubbleNip.leftBottom
            : BubbleNip.rightBottom,
  );
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Chat(
      // ...
      bubbleBuilder: _bubbleBuilder,
    ),
  );
}
```

This is how it would look like

<img src="https://user-images.githubusercontent.com/14123304/133879196-ef3e3655-58c7-48b7-a0d6-084eb8968df9.png" width="288px" alt="Custom chat bubbles" />

## Custom messages

Use the `customMessageBuilder` function to build whatever message you want. To store the data use a `metadata` map of the `CustomMessage`. You can have multiple different custom messages, you will need to identify them based on some property inside the `metadata` and build accordingly.

## Pagination

Use `onEndReached`, `onEndReachedThreshold` and `isLastPage` parameters to control pagination. To learn more see [API reference](https://pub.dev/documentation/flutter_chat_ui/latest/flutter_chat_ui/ChatList-class.html). Here is a simple example based on a [basic usage](basic-usage):

```dart
// ...
import 'package:http/http.dart' as http;

class _MyHomePageState extends State<MyHomePage> {
  int _page = 0;
  // ...
  @override
  void initState() {
    super.initState();
    _handleEndReached();
  }

  Future<void> _handleEndReached() async {
    final uri = Uri.parse(
      'https://api.instantwebtools.net/v1/passenger?page=$_page&size=20',
    );
    final response = await http.get(uri);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'] as List<dynamic>;
    final messages = data
        .map(
          (e) => types.TextMessage(
            author: _user,
            id: e['_id'] as String,
            text: e['name'] as String,
          ),
        )
        .toList();
    setState(() {
      _messages = [..._messages, ...messages];
      _page = _page + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Chat(
        // ...
        onEndReached: _handleEndReached,
      ),
    );
  }
}
```

## User avatars & names

To show user avatars & names use `showUserAvatars` and `showUserNames` parameters. Can be used separately. By default, the chat will select one of 10 provided colors as an avatar background and name text color. Color is calculated based on the user's `id` hash code, so it is unique in different rooms. To modify provided colors use `userAvatarNameColors` parameter in [theme](themes). If you want to have one color for everyone, just pass this color as a single item in the `userAvatarNameColors` list.
## Audio messages

You can also enabled audio message recording by providing a value for the `onAudioRecorded` callback function.

Note that this has certain limitations and prerequisites:

- All the audio recording and playback functionality uses [`flutter_sound`](https://pub.dev/packages/flutter_sound), which is only supported on Android, iOS and web, but not on desktop (Windows, MacOS, Linux). So if your application runs on a desktop, you should not use this functionality.
- On mobile platforms (iOS and Android), you need to ask for permission to access the microphone before you enable this feature in the Chat widget. On the web, the browser does it automatically as soon as the sound recorder tries to open an audio session. To ask for this permission on mobile, you can use the [`permission_handler`](https://pub.dev/packages/permission_handler) Flutter library, as demonstrated in the example app. See the documentation of this plugin for setup instructions.
- To enabled this feature, on the web, you need to add a few scripts to your `index.html`'s head section, as described [here](https://tau.canardoux.xyz/guides_web.html), and as demonstrated in the example app.
- Unfortunately, there is no audio encoding format that can be [encoded and decoded across all platforms](https://tau.canardoux.xyz/guides_codec.html). So in addition to the path of the file where the audio was recorded (`filePath`), `onAudioRecorded` also provides you with the MIME type of the recorded audio. It can be important to take that into consideration as messages recorded on one platform should be uploaded to your backend so that they can be played back on any other platform that you support. So you might need to convert files if you want to support all web browsers.
    - On mobile platforms (Android and iOS), since they can both record and play AAC/ADTS, the MIME type is audio/aac
    - On the web, things are a little more complicated: on Chrome, Firefox or Edge, you should get `audio/webm;codecs="opus"` (OPUS/WEBM), but on Safari, you will get `audio/aac` (AAC/MP4)

In addition to the file path of the recorded file, the MIME type, and the length of the recording, `onAudioRecorded` also provides you with a `waveForm` that is a list of `double` decibel levels that can be useful to show a visual representation of your recording, similar to the one that appears in the audio message bubble. Note that web browsers don't expose this decibel level data so messages recorded on the web appear as a simple track and return a `waveForm` that's just a list of 0.0 levels.

Note that `onAudioRecorded` is a `Future<bool>` async function that should return true or false depending on whether the upload of the audio recording was successful. While your implementation of `onAudioRecorded` is in progress, the send button will in the chat input will be replaced by a progress indicator and the buttons of the recorder will be disabled.

Inside `onAudioRecorded`, you can you the `filePath` parameter to retrieve the local temporary file from the file system using `File` on mobile platforms. But on the web again, things are a little different: `flutter_sound` stores the file in session storage and in `filePath`, you get a blob URL that you can use to download the data served locally at that URL using something like the `http` package. Here is the relevant code demonstrating the two approaches in the example app:

``` 
if (kIsWeb) {
  final response = await http.get(Uri.parse(filePath));
  final data = response.bodyBytes;
  print('audio recording size: ${data.length}');
} else {
  final file = File(filePath);
  final data = await file.readAsBytes();
  print('audio recording size: ${data.length}');
}
```

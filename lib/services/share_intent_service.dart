import 'package:receive_sharing_intent/receive_sharing_intent.dart';

Stream<List<SharedMediaFile>> get sharedMediaStream {
  return ReceiveSharingIntent.instance.getMediaStream();
}

Future<List<SharedMediaFile>> get sharedMediaInitial async {
  return ReceiveSharingIntent.instance.getInitialMedia();
}

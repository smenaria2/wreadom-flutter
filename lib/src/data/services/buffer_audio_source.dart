// ignore_for_file: experimental_member_use
import 'dart:async';
import 'package:just_audio/just_audio.dart';

class BufferAudioSource extends StreamAudioSource {
  final List<int> bytes;
  final String contentType;

  BufferAudioSource(this.bytes, {super.tag, this.contentType = 'audio/mpeg'});

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: contentType,
    );
  }
}

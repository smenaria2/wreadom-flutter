import 'clipboard_writer_io.dart'
    if (dart.library.html) 'clipboard_writer_web.dart';

Future<bool> writeClipboardText(String text) => writeClipboardTextImpl(text);

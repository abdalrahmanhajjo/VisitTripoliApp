import 'package:share_plus/share_plus.dart';

/// Shares plain text via `SharePlus.instance` (current share_plus API).
Future<ShareResult?> sharePlainText(String text, {String? subject}) {
  return SharePlus.instance.share(ShareParams(text: text, subject: subject));
}

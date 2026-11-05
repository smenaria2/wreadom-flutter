/// Helpers for building UPI payment links (`upi://pay?...`) and validating
/// UPI IDs (VPAs) and transaction reference numbers (UTR).
///
/// Wreadom never processes the payment: the link only pre-fills the payee,
/// amount and note in the reader's own UPI app.
class UpiLinkBuilder {
  const UpiLinkBuilder._();

  static final RegExp _vpaPattern = RegExp(
    r'^[a-z0-9._\-]{2,64}@[a-z][a-z0-9.\-]{1,31}$',
  );
  static final RegExp _utrPattern = RegExp(r'^\d{12}$');

  /// Returns a lowercase, trimmed VPA or null when [input] is not valid.
  static String? normalizeVpa(String? input) {
    final value = input?.trim().toLowerCase();
    if (value == null || value.isEmpty) return null;
    return _vpaPattern.hasMatch(value) ? value : null;
  }

  /// Returns the 12-digit UTR or null when [input] is not valid.
  static String? normalizeUtr(String? input) {
    final value = input?.trim();
    if (value == null || value.isEmpty) return null;
    return _utrPattern.hasMatch(value) ? value : null;
  }

  /// Builds a `upi://pay` link. Spaces are encoded as `%20` because several
  /// UPI apps mishandle `+`.
  static String build({
    required String vpa,
    required String payeeName,
    int? amountInr,
    String note = 'Wreadom support',
  }) {
    final params = <String, String>{
      'pa': vpa,
      'pn': _truncate(payeeName.trim().isEmpty ? vpa : payeeName.trim(), 40),
      if (amountInr != null && amountInr > 0) 'am': '$amountInr.00',
      'cu': 'INR',
      'tn': _truncate(note, 50),
    };
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return 'upi://pay?$query';
  }

  static String _truncate(String value, int max) =>
      value.length <= max ? value : value.substring(0, max);
}

/// InfoText represents a section of information about a historical site.
/// Each InfoText has a title, content value, and optional date.
class InfoText {
  final String title;
  final String value;
  final String date;

  /// Create a new InfoText object
  InfoText({required this.title, required this.value, this.date = ""});

  /// Convert to string format for Firebase storage
  @override
  String toString() {
    return "$title{IFDIV}$value{IFDIV}$date";
  }

  /// Create a copy of this InfoText with optional new values
  InfoText copyWith({
    String? title,
    String? value,
    String? date,
  }) {
    return InfoText(
      title: title ?? this.title,
      value: value ?? this.value,
      date: date ?? this.date,
    );
  }
}

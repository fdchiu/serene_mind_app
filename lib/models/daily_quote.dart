class DailyQuote {
  const DailyQuote({required this.text, required this.author});

  final String text;
  final String author;

  Map<String, dynamic> toJson() => {'text': text, 'author': author};

  factory DailyQuote.fromJson(Map<String, dynamic> json) {
    return DailyQuote(
      text: json['text'] as String? ?? '',
      author: json['author'] as String? ?? '',
    );
  }
}

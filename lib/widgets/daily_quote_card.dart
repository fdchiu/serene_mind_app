import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/daily_quote.dart';

class DailyQuoteCard extends StatelessWidget {
  const DailyQuoteCard({super.key, required this.quote});

  final DailyQuote quote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: glassDecoration(context).copyWith(
        gradient: const LinearGradient(
          colors: [Color(0x3321314F), Color(0x33123553)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            '"${quote.text}"',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Text(
            '— ${quote.author}',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

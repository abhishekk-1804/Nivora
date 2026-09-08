import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuoteService {
  final Map<String, dynamic> data;

  QuoteService(this.data);

  static Future<QuoteService> init() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/quotes.json');
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      return QuoteService(jsonData);
    } catch (e) {
      // Fallback
      return QuoteService({
        'general': ['Your body is not broken — it is asking to be understood.']
      });
    }
  }

  String getTodaysQuote() {
    final now = DateTime.now();
    
    // Check holidays first (format: MM-DD)
    final monthStr = now.month.toString().padLeft(2, '0');
    final dayStr = now.day.toString().padLeft(2, '0');
    final dateKey = '$monthStr-$dayStr';
    
    final holidays = data['holidays'] as Map<String, dynamic>? ?? {};
    if (holidays.containsKey(dateKey)) {
      return holidays[dateKey] as String;
    }

    final isPM = now.hour >= 12;
    // Rotate twice a day (AM/PM)
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final seed = (dayOfYear * 2) + (isPM ? 1 : 0);

    // If it's Sunday
    if (now.weekday == DateTime.sunday) {
      final sundayQuotes = List<String>.from(data['sunday'] ?? []);
      if (sundayQuotes.isNotEmpty) {
        return sundayQuotes[seed % sundayQuotes.length];
      }
    }

    final generalQuotes = List<String>.from(data['general'] ?? []);
    final memes = List<String>.from(data['memes'] ?? []);
    
    if (generalQuotes.isEmpty) return 'Have a wonderful day.';

    // Mix in memes occasionally (e.g., every 5th rotation)
    if (seed % 5 == 0 && memes.isNotEmpty) {
      return memes[(seed ~/ 5) % memes.length];
    }

    return generalQuotes[seed % generalQuotes.length];
  }
}

// Global provider for the QuoteService.
final quoteServiceProvider = FutureProvider<QuoteService>((ref) async {
  return await QuoteService.init();
});

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class GameResult {
  const GameResult({
    required this.id,
    required this.gameId,
    required this.dateKey,
    required this.won,
    required this.score,
    required this.attempts,
    required this.streak,
    required this.completedAt,
    this.metadata = const {},
  });

  final String id;
  final String gameId;
  final String dateKey;
  final bool won;
  final int score;
  final int attempts;
  final int streak;
  final DateTime completedAt;
  final Map<String, String> metadata;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameId': gameId,
      'dateKey': dateKey,
      'won': won,
      'score': score,
      'attempts': attempts,
      'streak': streak,
      'completedAt': completedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory GameResult.fromJson(Map<String, dynamic> json) {
    return GameResult(
      id: json['id'] as String,
      gameId: json['gameId'] as String,
      dateKey: json['dateKey'] as String,
      won: json['won'] as bool? ?? false,
      score: json['score'] as int? ?? 0,
      attempts: json['attempts'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      completedAt:
          DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      metadata: (json['metadata'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, '$value'),
      ),
    );
  }
}

abstract class GameResultsRepository {
  Future<List<GameResult>> readResults();

  Future<void> writeResult(GameResult result);
}

class LocalGameResultsRepository implements GameResultsRepository {
  LocalGameResultsRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _resultsKey = 'game.results';

  @override
  Future<List<GameResult>> readResults() async {
    final values = _preferences.getStringList(_resultsKey) ?? [];

    return values.map(_decodeResult).nonNulls.toList()..sort(
      (first, second) => first.completedAt.compareTo(second.completedAt),
    );
  }

  @override
  Future<void> writeResult(GameResult result) async {
    final results = await readResults();
    final nextResults = [
      for (final existingResult in results)
        if (existingResult.id != result.id) existingResult,
      result,
    ]..sort((first, second) => first.completedAt.compareTo(second.completedAt));

    await _preferences.setStringList(
      _resultsKey,
      nextResults.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  GameResult? _decodeResult(String value) {
    try {
      return GameResult.fromJson(jsonDecode(value) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

class MemoryGameResultsRepository implements GameResultsRepository {
  final Map<String, GameResult> _resultsById = {};

  @override
  Future<List<GameResult>> readResults() async {
    return _resultsById.values.toList()..sort(
      (first, second) => first.completedAt.compareTo(second.completedAt),
    );
  }

  @override
  Future<void> writeResult(GameResult result) async {
    _resultsById[result.id] = result;
  }
}

import 'dart:convert';
import 'package:sqflite/sqflite.dart';


/// write operation to survive so it can be synced later.
class WriteQueue {
  final Database _db;

  WriteQueue(this._db);

  /// Enqueue a write operation
  Future<void> enqueue({
    required String operation,
    required dynamic payload,
  }) async {
    final payloadStr = payload is String ? payload : jsonEncode(payload);
    await _db.insert('pending_writes', {
      'operation': operation,
      'payload': payloadStr,
      'created_at': DateTime.now().toIso8601String(),
    });
  }


  Future<int> processAll({
    required Future<void> Function(String operation, Map<String, dynamic> payload)
    onProcess,
  }) async {
    final pending = await _db.query(
      'pending_writes',
      orderBy: 'created_at ASC',
    );

    var processed = 0;

    for (final row in pending) {
      try {
        final operation = row['operation'] as String;
        final payloadStr = row['payload'] as String;
        final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
        final id = row['id'] as int;

        await onProcess(operation, payload);

        // Only remove after successful processing
        await _db.delete('pending_writes', where: 'id = ?', whereArgs: [id]);
        processed++;
      } catch (e) {
        break;
      }
    }

    return processed;
  }

  Future<int> get pendingCount async {
    final result = await _db.rawQuery('SELECT COUNT(*) as count FROM pending_writes');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
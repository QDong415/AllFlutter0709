import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_summary.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class ChatLocalDataSource {
  ChatLocalDataSource();

  static const _databaseName = 'conversation.db';
  static const _databaseVersion = 3;
  static const _chatTable = 'chat';

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final directory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(directory.path, _databaseName);
    final db = await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_chatTable (
            dbid INTEGER PRIMARY KEY AUTOINCREMENT,
            userid TEXT NOT NULL,
            msgid INTEGER DEFAULT 0,
            client_messageid TEXT DEFAULT '',
            targetid TEXT NOT NULL,
            other_userid TEXT DEFAULT '',
            other_name TEXT DEFAULT '',
            other_photo TEXT DEFAULT '',
            other_user_type INTEGER DEFAULT 0,
            content TEXT DEFAULT '',
            create_time INTEGER NOT NULL,
            state INTEGER NOT NULL,
            type INTEGER NOT NULL,
            subtype INTEGER NOT NULL,
            filename TEXT DEFAULT '',
            extend TEXT DEFAULT '',
            issender INTEGER NOT NULL,
            hadread INTEGER NOT NULL,
            local_file_path TEXT DEFAULT '',
            upload_progress INTEGER DEFAULT 0
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_chat_user_target_time ON $_chatTable(userid, targetid, create_time)',
        );
        await db.execute(
          'CREATE INDEX idx_chat_user_msgid ON $_chatTable(userid, msgid)',
        );
        await db.execute(
          'CREATE INDEX idx_chat_user_client_msgid ON $_chatTable(userid, client_messageid)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $_chatTable ADD COLUMN other_user_type INTEGER DEFAULT 0',
          );
        }
        if (oldVersion < 3) {
          await _stripIncomingVoiceHadPlay(db);
        }
      },
    );
    _database = db;
    return db;
  }

  /// 对方发来的语音 extend 里可能带着发送方的 hadplay，入库后应视为未读。
  static Future<void> _stripIncomingVoiceHadPlay(Database db) async {
    final rows = await db.query(
      _chatTable,
      columns: const ['dbid', 'extend'],
      where: 'issender = 0 AND subtype = ?',
      whereArgs: [ConversationMessageType.voice.subtype],
    );
    for (final row in rows) {
      final extend = row['extend']?.toString() ?? '';
      final cleaned = ConversationMessage.stripIncomingVoiceHadPlay(extend);
      if (cleaned == extend) {
        continue;
      }
      await db.update(
        _chatTable,
        {'extend': cleaned},
        where: 'dbid = ?',
        whereArgs: [row['dbid']],
      );
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<int> getTotalUnreadCount(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(1) AS count FROM $_chatTable WHERE userid = ? AND hadread = 0',
      [userId],
    );
    return _readCount(result);
  }

  Future<List<ConversationSummary>> getConversationList(String userId) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT * FROM $_chatTable
      WHERE userid = ? AND dbid IN (
        SELECT MAX(dbid) FROM $_chatTable WHERE userid = ? GROUP BY targetid
      )
      ORDER BY create_time DESC, dbid DESC
    ''',
      [userId, userId],
    );

    final result = <ConversationSummary>[];
    for (final row in rows) {
      final conversationId = _readString(row['targetid']);
      final unreadCount = await getUnreadCountByConversation(
        userId,
        conversationId,
        db: db,
      );
      final otherName = _readString(row['other_name']);
      final otherPhoto = _readString(row['other_photo']);
      result.add(
        ConversationSummary(
          conversationId: conversationId,
          otherUserId: _readString(row['other_userid']),
          name: otherName.isEmpty ? '用户$conversationId' : otherName,
          avatar: otherPhoto,
          latestMessage: ConversationMessage.fromDbMap(row).previewText,
          latestTimeSeconds: _readInt(row['create_time']),
          unreadCount: unreadCount,
          type: _readInt(row['type'], fallback: 1),
          userType: _readInt(row['other_user_type']),
        ),
      );
    }
    return result;
  }

  Future<List<ConversationMessage>> getMessages(
    String userId,
    String conversationId,
  ) async {
    final db = await database;
    final rows = await db.query(
      _chatTable,
      where: 'userid = ? AND targetid = ?',
      whereArgs: [userId, conversationId],
      orderBy: 'create_time ASC, dbid ASC',
    );
    return rows.map(ConversationMessage.fromDbMap).toList(growable: false);
  }

  Future<int> getUnreadCountByConversation(
    String userId,
    String conversationId, {
    Database? db,
  }) async {
    final databaseRef = db ?? await database;
    final result = await databaseRef.rawQuery(
      'SELECT COUNT(1) AS count FROM $_chatTable WHERE userid = ? AND targetid = ? AND hadread = 0',
      [userId, conversationId],
    );
    return _readCount(result);
  }

  Future<void> insertMessage(String userId, ConversationMessage message) async {
    final db = await database;
    if (await _messageExists(userId, message, db)) {
      return;
    }

    await db.insert(_chatTable, message.toDbMap(userId: userId));
  }

  Future<int> insertMessages(
    String userId,
    List<ConversationMessage> messages,
  ) async {
    if (messages.isEmpty) {
      return 0;
    }

    var inserted = 0;
    final db = await database;
    await db.transaction((txn) async {
      for (final message in messages) {
        if (await _messageExists(userId, message, txn)) {
          continue;
        }
        await txn.insert(_chatTable, message.toDbMap(userId: userId));
        inserted++;
      }
    });
    return inserted;
  }

  Future<void> updateMessageStatus(
    String userId,
    String clientMessageId,
    ConversationMessageStatus status,
  ) async {
    final db = await database;
    await db.update(
      _chatTable,
      {'state': status.code},
      where: 'userid = ? AND client_messageid = ?',
      whereArgs: [userId, clientMessageId],
    );
  }

  /// 按服务端 msgid 更新发送/下载状态。
  Future<void> updateMessageStatusByMsgId(
    String userId,
    int msgId,
    ConversationMessageStatus status,
  ) async {
    if (msgId <= 0) {
      return;
    }
    final db = await database;
    await db.update(
      _chatTable,
      {'state': status.code},
      where: 'userid = ? AND msgid = ?',
      whereArgs: [userId, msgId],
    );
  }

  Future<void> updateUploadProgress(
    String userId,
    String clientMessageId,
    int progress,
  ) async {
    final db = await database;
    await db.update(
      _chatTable,
      {'upload_progress': progress.clamp(0, 100)},
      where: 'userid = ? AND client_messageid = ?',
      whereArgs: [userId, clientMessageId],
    );
  }

  /// 写入语音本地路径，优先 msgid，其次 client_messageid。
  Future<void> updateLocalFilePath({
    required String userId,
    required String localFilePath,
    int msgId = 0,
    String clientMessageId = '',
  }) async {
    final db = await database;
    if (msgId > 0) {
      await db.update(
        _chatTable,
        {'local_file_path': localFilePath},
        where: 'userid = ? AND msgid = ?',
        whereArgs: [userId, msgId],
      );
      return;
    }
    if (clientMessageId.trim().isEmpty) {
      return;
    }
    await db.update(
      _chatTable,
      {'local_file_path': localFilePath},
      where: 'userid = ? AND client_messageid = ?',
      whereArgs: [userId, clientMessageId],
    );
  }

  /// 更新消息 extend（语音 hadplay 等）。
  Future<void> updateMessageExtend({
    required String userId,
    required int msgId,
    required String extend,
  }) async {
    if (msgId <= 0) {
      return;
    }
    final db = await database;
    await db.update(
      _chatTable,
      {'extend': extend},
      where: 'userid = ? AND msgid = ?',
      whereArgs: [userId, msgId],
    );
  }

  Future<void> markConversationRead(
    String userId,
    String conversationId,
  ) async {
    final db = await database;
    await db.update(
      _chatTable,
      {'hadread': 1},
      where: 'userid = ? AND targetid = ?',
      whereArgs: [userId, conversationId],
    );
  }

  /// 删除指定会话的全部本地消息（对齐 Android `clearChatWithTargetid`）。
  Future<void> deleteConversation(String userId, String conversationId) async {
    final db = await database;
    await db.delete(
      _chatTable,
      where: 'userid = ? AND targetid = ?',
      whereArgs: [userId, conversationId],
    );
  }

  /// 删除单条本地消息，优先 [clientMessageId]，否则 [msgId]。
  Future<void> deleteMessage({
    required String userId,
    required String clientMessageId,
    required int msgId,
  }) async {
    final db = await database;
    final clientId = clientMessageId.trim();
    if (clientId.isNotEmpty) {
      await db.delete(
        _chatTable,
        where: 'userid = ? AND client_messageid = ?',
        whereArgs: [userId, clientId],
      );
      return;
    }
    if (msgId <= 0) {
      return;
    }
    await db.delete(
      _chatTable,
      where: 'userid = ? AND msgid = ?',
      whereArgs: [userId, msgId],
    );
  }

  Future<ConversationMessage?> findMessageByClientId(
    String userId,
    String clientMessageId,
  ) async {
    final db = await database;
    final rows = await db.query(
      _chatTable,
      where: 'userid = ? AND client_messageid = ?',
      whereArgs: [userId, clientMessageId],
      limit: 1,
      orderBy: 'dbid DESC',
    );
    if (rows.isEmpty) {
      return null;
    }
    return ConversationMessage.fromDbMap(rows.first);
  }

  Future<bool> _messageExists(
    String userId,
    ConversationMessage message,
    DatabaseExecutor executor,
  ) async {
    if (message.msgId > 0) {
      final rows = await executor.query(
        _chatTable,
        columns: const ['dbid'],
        where: 'userid = ? AND msgid = ?',
        whereArgs: [userId, message.msgId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return true;
      }
    }

    if (message.clientMessageId.trim().isNotEmpty) {
      final rows = await executor.query(
        _chatTable,
        columns: const ['dbid'],
        where: 'userid = ? AND client_messageid = ?',
        whereArgs: [userId, message.clientMessageId],
        limit: 1,
      );
      return rows.isNotEmpty;
    }
    return false;
  }

  static int _readCount(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) {
      return 0;
    }
    return _readInt(rows.first['count']);
  }

  static String _readString(Object? value) => value?.toString().trim() ?? '';

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

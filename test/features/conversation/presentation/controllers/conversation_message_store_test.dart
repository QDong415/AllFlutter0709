import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:all_flutter0709/features/conversation/presentation/controllers/conversation_message_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConversationMessageStore', () {
    test('不同会话互不通知并可增量替换消息', () {
      final store = ConversationMessageStore();
      addTearDown(store.dispose);
      var firstConversationNotifications = 0;
      var secondConversationNotifications = 0;
      store.listenableOf('first').addListener(() {
        firstConversationNotifications++;
      });
      store.listenableOf('second').addListener(() {
        secondConversationNotifications++;
      });

      final pendingMessage = _message(
        clientMessageId: 1001,
        status: ConversationMessageStatus.sending,
      );
      store.append('first', pendingMessage);
      store.replace(
        'first',
        pendingMessage.copyWith(
          msgId: 88,
          status: ConversationMessageStatus.sent,
        ),
      );

      final messageList = store.stateOf('first').requireValue;
      expect(messageList.single.msgId, 88);
      expect(messageList.single.status, ConversationMessageStatus.sent);
      expect(firstConversationNotifications, 2);
      expect(secondConversationNotifications, 0);
    });

    test('上传进度不足 5% 时不通知界面', () {
      final store = ConversationMessageStore();
      addTearDown(store.dispose);
      final pendingMessage = _message(
        clientMessageId: 1002,
        status: ConversationMessageStatus.sending,
      );
      store.append('first', pendingMessage);
      var notifications = 0;
      store.listenableOf('first').addListener(() {
        notifications++;
      });

      store.updateUploadProgress(
        conversationId: 'first',
        clientMessageId: 1002,
        progress: 3,
      );
      store.updateUploadProgress(
        conversationId: 'first',
        clientMessageId: 1002,
        progress: 5,
      );

      expect(notifications, 1);
      expect(store.stateOf('first').requireValue.single.uploadProgress, 5);
    });
  });
}

ConversationMessage _message({
  required int clientMessageId,
  required ConversationMessageStatus status,
}) {
  return ConversationMessage(
    msgId: 0,
    clientMessageId: clientMessageId,
    conversationId: 'first',
    otherUserId: 'first',
    otherName: '测试用户',
    otherPhoto: '',
    content: 'hello',
    createTimeSeconds: 1,
    status: status,
    type: 1,
    messageType: ConversationMessageType.text,
    filename: '',
    extend: '',
    isSender: true,
    isRead: true,
  );
}

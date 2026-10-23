import 'package:all_flutter0709/core/network/request_sign.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('按 key 排序，sig 先换成密钥再 MD5', () {
    final sig = RequestSign.sign(<String, String>{
      'b': '2',
      'userid': '',
      'a': '1',
      'sig': 'should-be-replaced',
    });

    // a=1&b=2&sig=iTopic2015&userid=
    expect(sig, '295d848ee691fe14985b6bc5a66f0a3e');
  });

  test('参数顺序不影响签名', () {
    final left = RequestSign.sign(<String, String>{'b': '2', 'a': '1'});
    final right = RequestSign.sign(<String, String>{'a': '1', 'b': '2'});
    expect(left, right);
  });
}

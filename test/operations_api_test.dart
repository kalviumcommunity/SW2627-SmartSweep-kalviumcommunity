import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_sweep/operations/api.dart';

void main() {
  test('login token is attached to subsequent operational reads', () async {
    final api = OperationsApi(client: MockClient((request) async {
      if (request.url.path == '/api/login') {
        expect(jsonDecode(request.body)['email'], 'supervisor@example.test');
        return http.Response('{"token":"test-session"}',200);
      }
      expect(request.headers['Authorization'],'Bearer test-session');
      return http.Response('{"routes":[]}',200);
    }));
    await api.login('supervisor@example.test','test-only-password');
    expect((await api.request('state'))['routes'],isEmpty);
    api.close();
  });
  test('expired session clears token and surfaces API error', () async {
    final api = OperationsApi(client: MockClient((_) async =>
      http.Response('{"error":"Please sign in again."}',401)));
    api.token='expired';
    await expectLater(api.request('state'),throwsException);
    expect(api.token,isNull);
    api.close();
  });
}

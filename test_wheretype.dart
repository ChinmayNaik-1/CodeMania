import 'dart:convert';

void main() {
  final jsonStr = '[{"id": 1}]';
  final data = jsonDecode(jsonStr);
  print(data is List);
  print((data as List).whereType<Map>().length);
}

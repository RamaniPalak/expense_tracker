import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  // Test registration - Serverpod expects a 'user' parameter with serialized User object
  print('Testing registration API...');
  var registerResponse = await http.post(
    Uri.parse('http://localhost:8080/auth/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'user': {
        'name': 'Test User',
        'email': 'test@example.com',
        'password': 'password123',
      }
    }),
  );

  print('Registration Status: ${registerResponse.statusCode}');
  print('Registration Response: ${registerResponse.body}');

  // Test login
  print('\nTesting login API...');
  var loginResponse = await http.post(
    Uri.parse('http://localhost:8080/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': 'test@example.com',
      'password': 'password123',
    }),
  );

  print('Login Status: ${loginResponse.statusCode}');
  print('Login Response: ${loginResponse.body}');
}

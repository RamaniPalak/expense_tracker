import 'package:backend_client/backend_client.dart';

void main() async {
  var client = Client('http://localhost:8080/');
  try {
    var email = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
    print('Testing registration for $email...');
    var user = User(
      name: 'Test Registry',
      email: email,
      password: 'Password@123',
    );
    var success = await client.auth.register(user);
    if (success) {
      print('REGISTRATION_SUCCESS');
    } else {
      print('REGISTRATION_FAILED: Email might exist');
    }
  } catch (e) {
    print('REGISTRATION_ERROR: $e');
  } finally {
    client.close();
  }
}

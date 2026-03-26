import 'package:backend_client/backend_client.dart';

void main() async {
  var client = Client('http://localhost:8080/');
  try {
    print('Testing login for test@yopmail.com...');
    var user = await client.auth.login('test@yopmail.com', 'Test@123');
    if (user != null) {
      print('LOGIN_SUCCESS: Name=${user.name}, Email=${user.email}');
    } else {
      print('LOGIN_FAILED: No user returned');
    }
  } catch (e) {
    print('LOGIN_ERROR: $e');
  } finally {
    client.close();
  }
}

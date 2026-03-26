import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class AuthEndpoint extends Endpoint {
  Future<bool> register(Session session, User user) async {
    // Check if user already exists
    var existingUser = await User.db.findFirstRow(
      session,
      where: (t) => t.email.equals(user.email),
    );

    if (existingUser != null) {
      return false;
    }

    // In a real app, hash the password here!
    user.createdAt = DateTime.now();
    await User.db.insertRow(session, user);
    return true;
  }

  Future<User?> login(Session session, String email, String password) async {
    // Check credentials
    var user = await User.db.findFirstRow(
      session,
      where: (t) => t.email.equals(email) & t.password.equals(password),
    );

    return user;
  }
}

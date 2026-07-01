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

  Future<bool> changePassword(
      Session session, String email, String oldPassword, String newPassword) async {
    // Check old password
    var user = await User.db.findFirstRow(
      session,
      where: (t) => t.email.equals(email) & t.password.equals(oldPassword),
    );

    if (user == null) {
      return false;
    }

    user.password = newPassword;
    await User.db.updateRow(session, user);
    return true;
  }

  Future<User?> updateProfile(
      Session session, String email, String name, String? imagePath) async {
    var user = await User.db.findFirstRow(
      session,
      where: (t) => t.email.equals(email),
    );

    if (user == null) {
      return null;
    }

    user.name = name;
    user.imagePath = imagePath;
    
    await User.db.updateRow(session, user);
    return user;
  }
}

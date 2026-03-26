import 'package:postgres/postgres.dart';

void main() async {
  final connection = await Connection.open(
    Endpoint(
      host: 'dpg-d72h8g4r85hc73dpvam0-a.oregon-postgres.render.com',
      database: 'expense_tracker_db_sxin',
      username: 'expense_tracker_db_sxin_user',
      password: '9G3cVlXA8D3UAIv7JiMHokjqtg0V7a5l',
    ),
    settings: ConnectionSettings(sslMode: SslMode.require),
  );

  try {
    final results = await connection.execute(
      "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'",
    );
    print('Tables in database:');
    for (final row in results) {
      print('- ${row[0]}');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    await connection.close();
  }
}

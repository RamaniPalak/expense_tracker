import 'package:postgres/postgres.dart';

void main() async {
  final connection = await Connection.open(
    Endpoint(
      host: 'dpg-d882i1vavr4c73dvmjag-a.singapore-postgres.render.com',
      database: 'expense_tracker_db_sxin_5fyj',
      username: 'expense_tracker_db_sxin_5fyj_user',
      password: 'Hvna8ky0VCcoy769sMlhgfSbH1AXfY60',
    ),
    settings: ConnectionSettings(sslMode: SslMode.require),
  );

  try {
    final results = await connection.execute(
      "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'",
    );
  } catch (e) {
    print('Error: $e');
  } finally {
    await connection.close();
  }
}

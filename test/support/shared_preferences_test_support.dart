import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> mockSharedPreferences() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

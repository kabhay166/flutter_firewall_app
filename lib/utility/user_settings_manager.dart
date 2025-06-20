import 'package:firewall_app/utility/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSettingsManager {
  static final UserSettingsManager _instance = UserSettingsManager._internal();
  final IITK_USERNAME = "IITK_USERNAME";
  final IITK_PASSWORD = "IITK_PASSWORD";
  factory UserSettingsManager() => _instance;

  UserSettingsManager._internal();


  Future<void> setUserSettings(String username,String password,bool rememberMe) async {
    await secureStorage.write(key: IITK_USERNAME, value: username);
    await secureStorage.write(key: IITK_PASSWORD, value: password);
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('rememberCredentials', rememberMe);
  }

  Future<Map<String,dynamic>> getUserSettings() async {

    String iitkUsername = await secureStorage.read(key: IITK_USERNAME) ?? "";
    String iitkPassword = await secureStorage.read(key:IITK_PASSWORD) ?? "";
    final prefs = await SharedPreferences.getInstance();
    bool rememberCredentials = prefs.getBool('rememberCredentials') ?? false;

    return {'iitkUsername': iitkUsername,'iitkPassword':iitkPassword, 'rememberCredentials': rememberCredentials};

  }

  Future<void> removeUserSettings() async {

    secureStorage.write(key: IITK_USERNAME, value: "");
    secureStorage.write(key: IITK_PASSWORD, value: "");
    final prefs =  await SharedPreferences.getInstance();
    prefs.setBool('rememberCredentials', false);

  }

  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    bool rememberCredentials = prefs.getBool('rememberCredentials') ?? false;
    return rememberCredentials;
  }


}

import 'dart:io';
import 'package:firewall_app/utility/user_settings_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:core';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';


class Authenticator {

  String _username;
  String _password;
  String? _keepAliveToken = "";
  static final _keepAliveMinutes = 30;
  static final _baseUrl = 'https://gateway.iitk.ac.in:1003/';
  static final _logoutUrl = "https://gateway.iitk.ac.in:1003/logout";
  static final _loginUrl = "https://gateway.iitk.ac.in:1003/login?";
  static final _keepAliveUrl = "https://gateway.iitk.ac.in:1003/keepalive?";

  Authenticator(this._username,this._password);



  Future<(bool,String?)> login() async{
    http.Response loginPageResponse;
    try {
      loginPageResponse = await http.get(
        Uri.parse(_loginUrl),
      );
    } on SocketException {
      return (false, "You are not connected to IITK Network.");
    } on http.ClientException {
      return (false, "Could not log in");
    } on Exception catch (e) {
      return (false, "Eror occured: $e");
    }


    final html = loginPageResponse.body;


    final magic = RegExp(r'name="magic" value="([^"]+)"').firstMatch(html)?.group(1);
    final redir = RegExp(r'name="4Tredir" value="([^"]+)"').firstMatch(html)?.group(1);

    if (magic == null || redir == null) {
      return (false, "Could not find login parameters");
    }



    Map<String,String> data = {
      'username':_username,
      'password':_password,
      'magic': magic,
      '4Tredir': '/',
    };


    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0',
        },
        body: data,
      );


      _keepAliveToken = RegExp(r"keepalive\?([a-zA-Z0-9]+)").firstMatch(response.body)?.group(1);

      if(_keepAliveToken == null) {
        return (false, "Failed to login with these credentials. Please check username and password");
      }


      return (true,null);

    } on SocketException {

      return (false, "You are not connected to IITK Network");
    } on Exception catch (e) {

      return (false,"Error occured: $e");
    }

  }


  static FutureOr<void> keepAlive( Map<String,dynamic> inputData) async  {

    final prefs = await SharedPreferences.getInstance();
    final timesKeptAlive = prefs.getInt('timesKeptAlive') ?? 0;

    if(timesKeptAlive == 40) {
      await Workmanager().cancelByUniqueName('KeepAliveTask');
      return;
    }

    String keepAliveToken = inputData['keepAliveToken'];
    String retryUrl = '$_keepAliveUrl$keepAliveToken';
    http.Response response;


    try {

      response = await http.get(Uri.parse(retryUrl),headers:{"User-Agent": "Mozilla/5.0","Connection": "keep-alive", "Accept": "*/*",});

      if(response.statusCode == 200){
        await prefs.setInt('timesKeptAlive',timesKeptAlive+1);

      } else {
        startLoginTask();
      }

    } on Exception {
      startLoginTask();

    }


  }


  static Future<void> loginTask() async {
    http.Response loginPageResponse;
    var userSettings = await UserSettingsManager().getUserSettings();

    try {
      loginPageResponse = await http.get(
        Uri.parse(_loginUrl),
      );
    } on SocketException {
      return;
    } on http.ClientException {
      return;
    } on Exception {
      return;
    }


    final html = loginPageResponse.body;


    final magic = RegExp(r'name="magic" value="([^"]+)"').firstMatch(html)?.group(1);
    final redir = RegExp(r'name="4Tredir" value="([^"]+)"').firstMatch(html)?.group(1);

    if (magic == null || redir == null) {
      return;
    }


    Map<String,String> data = {
      'username':userSettings['iitkUsername'],
      'password':userSettings['iitkPassword'],
      'magic': magic,
      '4Tredir': '/',
    };


    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0',
        },
        body: data,
      );


      String? keepAliveToken = RegExp(r"keepalive\?([a-zA-Z0-9]+)").firstMatch(response.body)?.group(1);

      if(keepAliveToken == null) {
        Workmanager().registerPeriodicTask('KeepAliveTask',

            'KeepAliveTask',frequency: Duration(minutes: _keepAliveMinutes),
            inputData: {'keepAliveToken':keepAliveToken},
            existingWorkPolicy: ExistingWorkPolicy.replace);
        return;
      }


      return;

    } on SocketException {

      return;
    } on Exception {

      return;
    }

  }


  static void startLoginTask() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('timesKeptAlive',0);
    await Workmanager().cancelByUniqueName('KeepAliveTask');
    Workmanager().registerOneOffTask('loginTask', 'loginTask');
  }


  Future<bool> checkState() async {
    try {
      http.Response? response = await http.get(Uri.parse(_loginUrl));
      if(response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } on Exception {
      return false;
    }
  }

  Future<bool> logout() async{

    http.Response? response;

    try {
      response = await http.get(
          Uri.parse(_logoutUrl).replace(queryParameters: {
            'username':_username,
            'password':_password,
          })).timeout(Duration(seconds: 5));


      if(response.statusCode == 200){
        return true;
      } else {
        return false;
      }

    } on TimeoutException {
      return false;
    }

    on SocketException {
      return false;

    }

  }

  void setCredentials(String username, String password) {
    _username = username;
    _password = password;
  }


  String getUsername() {
    return _username;
  }

  String getPassword() {
    return _password;
  }

  int getKeepAliveMinutes() {
    return _keepAliveMinutes;
  }

  String getKeepAliveToken() {
    return _keepAliveToken ?? "";
  }

  String getKeepAliveUrl() {
    return _keepAliveUrl;
  }

}


import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:core';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';


class Authenticator {

  String _username;
  String _password;
  final _keepAliveMinutes = 25;
  final _logoutUrl = "https://gateway.iitk.ac.in:1003/logout";
  final _loginUrl = "https://gateway.iitk.ac.in:1003/login?";
  final _keepAliveUrl = "https://gateway.iitk.ac.in:1003/keepalive";
  String _magicValue = "";

  Authenticator(this._username,this._password);



  Future<bool> login() async{

    final loginPageResponse = await http.get(
      Uri.parse(_loginUrl),
    );

    final html = loginPageResponse.body;


    final magic = RegExp(r'name="magic" value="([^"]+)"').firstMatch(html)?.group(1);
    final redir = RegExp(r'name="4Tredir" value="([^"]+)"').firstMatch(html)?.group(1);

    if (magic == null || redir == null) {
      return false;
    }

    _magicValue = magic;

    Map<String,String> data = {
      'username':_username,
      'password':_password,
      'magic': _magicValue,
      '4Tredir': '/',
    };


    try {
      final response = await http.post(
        Uri.parse('https://gateway.iitk.ac.in:1003/'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0',
        },
        body: data,
      );
      // print('Status: ${response.statusCode}');
      // print('Body: ${response.body}');
      return true;

    } catch (e) {
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

    on SocketException catch(e) {
      return false;

    }

  }


  static FutureOr<void> keepAlive( Map<String,dynamic> inputData) async  {

    print('[WorkManager]: Inside keep alive function');
    final prefs = await SharedPreferences.getInstance();
    final timesKeptAlive = prefs.getInt('timesKeptAlive') ?? 0;

    if(timesKeptAlive == 40) {
      await Workmanager().cancelByUniqueName('KeepAliveTask');
      return;
    }

    String keepAliveUrl = inputData['keepAliveUrl'];
    String magicValue = inputData['magicValue'];
    http.Response response;
    while(true) {

      try {
        response = await http.get(Uri.parse('$keepAliveUrl?$magicValue'));
      } on Exception catch (e) {
        await Workmanager().cancelByUniqueName('KeepAliveTask');
        break;
      }

      if(response.statusCode == 200){
        await prefs.setInt('timesKeptAlive',timesKeptAlive+1);
        break;

      } else {
        await prefs.setInt('timesKeptAlive',0);
        await Workmanager().cancelByUniqueName('KeepAliveTask');

        break;
      }


    }

  }

  void setCredentials(String username, String password) {
    this._username = username;
    this._password = password;
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

  String getMagicValue() {
    return _magicValue;
  }

  String getKeepAliveUrl() {
    return _keepAliveUrl;
  }

}
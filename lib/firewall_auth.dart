
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:core';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';


class Authenticator {

  String _username;
  String _password;
  final _keepAliveMinutes = 16;
  final _logoutUrl = "https://gateway.iitk.ac.in:1003/logout";
  final _loginUrl = "https://gateway.iitk.ac.in:1003/login?";
  final _keepAliveUrl = "https://gateway.iitk.ac.in:1003/keepalive?";
  String? _keepAliveToken = "";

  Authenticator(this._username,this._password);



  Future<bool> login() async{
    http.Response loginPageResponse;
    try {
      loginPageResponse = await http.get(
        Uri.parse(_loginUrl),
      );
    } on SocketException catch (e) {
      return false;
    } on http.ClientException catch (e) {
      return false;
    } on Exception catch (e) {
      return false;
    }


    final html = loginPageResponse.body;


    final magic = RegExp(r'name="magic" value="([^"]+)"').firstMatch(html)?.group(1);
    final redir = RegExp(r'name="4Tredir" value="([^"]+)"').firstMatch(html)?.group(1);

    if (magic == null || redir == null) {
      return false;
    }



    Map<String,String> data = {
      'username':_username,
      'password':_password,
      'magic': magic,
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
       print('Login response Body: ${response.body}');

      print('Login successfull with magic value = $magic now trying keepalive');

      _keepAliveToken = RegExp(r"keepalive\?([a-zA-Z0-9]+)").firstMatch(response.body)?.group(1);

      if(_keepAliveToken == null) {
        return false;
      }

      print('keep alive token is: $_keepAliveToken');
      String retryUrl = '$_keepAliveUrl$_keepAliveToken)';

      return true;

    } on SocketException catch (e) {
      print(e);
      return false;
    } on http.ClientException catch (e) {
      print(e);
      return false;
    } on Exception catch (e) {
      print(e);
      return false;
    }
  }





  static FutureOr<void> keepAlive( Map<String,dynamic> inputData) async  {

    print('[WorkManager]: Inside keep alive function');
    final prefs = await SharedPreferences.getInstance();
    final timesKeptAlive = prefs.getInt('timesKeptAlive') ?? 0;

    if(timesKeptAlive == 40) {
      print('Cancelling task from timesKeptAlive variable');
      await Workmanager().cancelByUniqueName('KeepAliveTask');
      return;
    }

    String keepAliveUrl = inputData['keepAliveUrl'];
    String keepAliveToken = inputData['keepAliveToken'];

    String retryUrl = '$keepAliveUrl$keepAliveToken';
    http.Response response;


      try {
        print('Trying the url: $retryUrl');
        response = await http.get(Uri.parse(retryUrl),headers:{"User-Agent": "Mozilla/5.0","Connection": "keep-alive", "Accept": "*/*",});
        print(response.body);

        if(response.statusCode == 200){
          await prefs.setInt('timesKeptAlive',timesKeptAlive+1);


        } else {
          print('response code is not 200. canceling task');
          await prefs.setInt('timesKeptAlive',0);
          await Workmanager().cancelByUniqueName('KeepAliveTask');


        }


      } on Exception catch (e) {
        print('Exception occurred cancelling the task. Exception is: ${e.toString()}');
        await Workmanager().cancelByUniqueName('KeepAliveTask');

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

  String getKeepAliveToken() {
    return _keepAliveToken ?? "";
  }

  String getKeepAliveUrl() {
    return _keepAliveUrl;
  }

}
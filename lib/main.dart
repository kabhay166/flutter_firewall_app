import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firewall_app/firewall_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(callbackDispatcher,isInDebugMode: true);
  runApp(const MyApp());

}


@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask( (task,inputData) async {

    if(task == 'KeepAliveTask') {
      print('Executing KeepAliveTask');
      await Authenticator.keepAlive(inputData!);

    }
    return Future.value(true);
  });


}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',


      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Login to IITK Wifi'),
    );
  }
}



class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;


  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final IITK_USERNAME = "IITK_USERNAME";
  final IITK_PASSWORD = "IITK_PASSWORD";
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late Authenticator _authenticator;
  String _username = "";
  String _password = "";
  bool _rememberMe = false;


  @override
  void initState() {
    super.initState();
    getUserSettings();

    _authenticator = Authenticator(_username, _password);

  }

  Future<void> getUserSettings() async {

      String iitkUsername = await secureStorage.read(key: IITK_USERNAME) ?? "";
      String iitkPassword = await secureStorage.read(key:IITK_PASSWORD) ?? "";
      final prefs = await SharedPreferences.getInstance();
      bool rememberCredentials = prefs.getBool('rememberCredentials') ?? false;

      print('iitkusername: $iitkUsername, iitkpassword: $iitkPassword');
      setState(()  {
          _username = iitkUsername;
          _password = iitkPassword;
          _rememberMe = rememberCredentials;
          _usernameController.text = iitkUsername;
          _passwordController.text = iitkPassword;
      });


  }

  Future<void> setUserSettings() async {
    await secureStorage.write(key: IITK_USERNAME, value: _usernameController.text);
    await secureStorage.write(key: IITK_PASSWORD, value: _passwordController.text);

    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('rememberCredentials', _rememberMe);
  }

  Future<void> removeUserSettings() async {
    _usernameController.text = "";
    _passwordController.text = "";

    secureStorage.write(key: IITK_USERNAME, value: "");
    secureStorage.write(key: IITK_PASSWORD, value: "");
    final prefs =  await SharedPreferences.getInstance();
    prefs.setBool('rememberCredentials', false);
    _rememberMe = false;
    setState(() {
      _username = "";
      _password = "";

    });

  }

  @override
  void dispose() {

    super.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
        
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
        
            SizedBox(height: 100),
            SizedBox(
        
              width: 250,
              child: Text('Please switch off the mobile network for the app to work.'),
            ),
        
            SizedBox(height: 50,),
        
            Center(
        
              child: Column(
        
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
        
        
                  credentialInput(context),
        
        
                  ElevatedButton(
        
                      onPressed: () async {
        
        
                              _username = _usernameController.text;
                              _password = _passwordController.text;
                              if(_username == "" || _password == "") {
                                const snackBar = SnackBar(content: Text('Username or password cannot be empty.'));
                                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                return;
                              }
        
                              _authenticator.setCredentials(_username, _password);

                           bool loginStatus = await _authenticator.login();
        
                           if(loginStatus) {
        
                             showMessage('Successfully logged in.');
        
                             if(_rememberMe) {
                               await setUserSettings();
                             }
                             final pref = await SharedPreferences.getInstance();
                             await pref.setInt('timesKeptAlive',0);
                             Workmanager().registerPeriodicTask('KeepAliveTask',
        
                                 'KeepAliveTask',frequency: Duration(minutes: _authenticator.getKeepAliveMinutes()),
                                 inputData: {'magicValue':_authenticator.getMagicValue(),
                                   'keepAliveUrl':_authenticator.getKeepAliveUrl()},
                                 existingWorkPolicy: ExistingWorkPolicy.replace);
        
                           } else {
                             showMessage('An error occured while logging in.');
        
                           }
        
                      },
        
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all<Color>(Colors.black),
                      ),
        
                      child: Text('Login', style: TextStyle(color: Colors.white,),),
        
                    ),
        
                  (_username != "" && _password != "")
                      ? ElevatedButton(onPressed: () { removeUserSettings();}, child: Text('Forget username and password'))
                      : SizedBox.shrink(),
        
                ],
              ),
            ),
          ],
        ),
      ),
       // This trailing comma makes auto-formatting nicer for build methods.
    );
  }


 Widget credentialInput(BuildContext context) {

     return Center(
       child: Column(
         children: [
           SizedBox(
               width: 200.0,
               child: TextField(
                 controller: _usernameController,
                 decoration: const InputDecoration(
                   border: OutlineInputBorder(),
                   hintText: 'username',
                 ),
                 autofocus: true,
               )
           ),

           SizedBox(
             height: 30.0,
           ),

           SizedBox(
               width: 200.0,
               child: TextField(

                 controller: _passwordController,
                 obscureText: true,
                 decoration: InputDecoration(
                   //labelText: 'password',
                   border: OutlineInputBorder(),
                   hintText: 'password',
                 ),
                 autofocus: true,
               )
           ),

           SizedBox(
             height: 10.0,
           ),


           !_rememberMe ?
           Center(
             child: Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [

                 Checkbox(value: _rememberMe, onChanged: (bool? value) {
                   setState(() {
                     _rememberMe = value!;
                   });
                 }),


                 Text('Remember username and password'),
               ],
             ),
           ) : SizedBox.shrink(),

         ],
       ),
     );
   }



 void showMessage(String message) {
   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
 }


}



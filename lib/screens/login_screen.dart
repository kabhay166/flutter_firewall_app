import 'package:firewall_app/firewall_auth.dart';
import 'package:firewall_app/utility/user_settings_manager.dart';
import 'package:firewall_app/widgets/show_message.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final IITK_USERNAME = "IITK_USERNAME";
  final IITK_PASSWORD = "IITK_PASSWORD";
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late Authenticator _authenticator;
  String _username = "";
  String _password = "";
  bool _rememberMe = false;
  bool rememberSetting = false;


  @override
  void initState() {
    super.initState();
    getUserSettings();
    _authenticator = Authenticator(_username, _password);

  }

  Future<void> getUserSettings() async {

    Map<String,dynamic> userSettings = await UserSettingsManager().getUserSettings();

    setState(()  {
      _username = userSettings['iitkUsername'];
      _password = userSettings['iitkPassword'];
      _rememberMe = userSettings['rememberCredentials'];
      _usernameController.text = userSettings['iitkUsername'];
      _passwordController.text = userSettings['iitkPassword'];
    });

    rememberSetting = await UserSettingsManager().getRememberMe();

  }

  Future<void> setUserSettings() async {
    String username = _usernameController.text;
    String password = _passwordController.text;
    bool rememberMe = _rememberMe;
    UserSettingsManager().setUserSettings(username, password, rememberMe);
  }

  Future<void> removeUserSettings() async {

    await UserSettingsManager().removeUserSettings();
    _usernameController.text = "";
    _passwordController.text = "";
    _rememberMe = false;
    setState(() {
      _username = "";
      _password = "";
      rememberSetting =  false;

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
        title: Text('Login to IITK Network'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [

              SizedBox(height: 100),

              SizedBox(

                width: 250,
                child: Text('Please switch off the mobile network for the app to work.'),
              ),

              SizedBox(height: 50,),

              credentialsInput(),

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
                    if(!mounted) return;
                    Navigator.pushNamed(context,'successPage');
                  } else {
                    if(!mounted) return;
                    showMessage(context, 'An error occurred while logging in.');

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
      ),
    );
  }


  Widget credentialsInput() {
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


          if (!rememberSetting) Center(
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
          ) else SizedBox.shrink(),

        ],
      ),
    );
  }
}

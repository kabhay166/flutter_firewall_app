import 'package:firewall_app/screens/login_screen.dart';
import 'package:firewall_app/screens/success_screen.dart';
import 'package:flutter/material.dart';
import 'package:firewall_app/firewall_auth.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(callbackDispatcher,isInDebugMode: true);
  runApp(const MyApp());

}


@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask( (task,inputData) async {

    if(task == 'KeepAliveTask') {
      await Authenticator.keepAlive(inputData!);

    }
    return Future.value(true);
  });


}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      routes: {
        'loginPage' : (context) => LoginScreen(),
        'successPage' : (context) => SuccessScreen(),
      },
      initialRoute: 'loginPage',

      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
    );
  }
}




import 'package:firewall_app/screens/login_screen.dart';
import 'package:firewall_app/screens/success_screen.dart';
import 'package:flutter/material.dart';
import 'package:firewall_app/utility/firewall_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(callbackDispatcher,isInDebugMode: true);
  runApp(const IITKFirewallLoginApp());

}


@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask( (task,inputData) async {

    if(task == 'KeepAliveTask') {
      await Authenticator.keepAlive(inputData!);

    }

    if(task == 'loginTask') {
      await Authenticator.loginTask();
    }
    return Future.value(true);
  });


}


final GoRouter _router = GoRouter(
    initialLocation: '/loginPage',
    routes: <RouteBase>[
  GoRoute(path: '/loginPage', builder: (BuildContext context, GoRouterState state) {
    return const LoginScreen();
  }),
  GoRoute(path: '/successPage', builder: (BuildContext context, GoRouterState state){
    return const SuccessScreen();
  } )
]);

class IITKFirewallLoginApp extends StatelessWidget {
  const IITKFirewallLoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      routerConfig: _router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
    );
  }
}




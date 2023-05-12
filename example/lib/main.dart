import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/about.dart';
import 'src/callscreen.dart';
import 'src/dialpad.dart';
import 'src/register.dart';

void main() {
  if (WebRTC.platformIsDesktop) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
  runApp(MyApp());
}

typedef PageContentBuilder = Widget Function(
    [SIPUAHelper? helper, Object? arguments]);

// ignore: must_be_immutable
class MyApp extends StatelessWidget {
  final SIPUAHelper _helper = SIPUAHelper();
  late SharedPreferences _preferences;

  Map<String, PageContentBuilder> routes = {
    '/home': ([SIPUAHelper? helper, Object? arguments]) =>
        DialPadWidget(helper),
    '/register': ([SIPUAHelper? helper, Object? arguments]) =>
        RegisterWidget(helper),
    '/callscreen': ([SIPUAHelper? helper, Object? arguments]) =>
        CallScreenWidget(helper, arguments as Call?),
    '/about': ([SIPUAHelper? helper, Object? arguments]) => AboutWidget(),
  };

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final String? name = settings.name;
    final PageContentBuilder? pageContentBuilder = routes[name!];
    if (pageContentBuilder != null) {
      if (settings.arguments != null) {
        final Route route = MaterialPageRoute<Widget>(
            builder: (context) =>
                pageContentBuilder(_helper, settings.arguments));
        return route;
      } else {
        final Route route = MaterialPageRoute<Widget>(
            builder: (context) => pageContentBuilder(_helper));
        return route;
      }
    }
    return null;
  }

  Future<String> initialRoute() async {
    _preferences = await SharedPreferences.getInstance();
    return validatePreference(_preferences) ? '/home' : '/register';
  }

  bool validatePreference(SharedPreferences preferences) {
    return preferences.containsKey('ws_uri') &&
        preferences.containsKey('password') &&
        preferences.containsKey('auth_user');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: FutureBuilder<String>(
        future: initialRoute(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Mientras el futuro está en progreso, puedes mostrar una pantalla de carga
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            // Si ocurre un error durante la obtención del futuro, puedes manejarlo aquí
            return Navigator(
              initialRoute: '/register',
              onGenerateRoute: _onGenerateRoute,
            );
          } else {
            // Una vez que el futuro se completa con éxito, puedes establecer la ruta inicial
            return Navigator(
              initialRoute: snapshot.data,
              onGenerateRoute: _onGenerateRoute,
            );
          }
        },
      ),
    );
  }
}

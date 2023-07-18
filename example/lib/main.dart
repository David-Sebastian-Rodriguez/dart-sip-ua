import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/about.dart';
import 'src/config.dart';
import 'src/callscreen.dart';
import 'src/dialpad.dart';
import 'src/register.dart';
import 'src/contacts.dart';
import 'src/call_history.dart';
import 'package:flutter/services.dart';

bool showSplashScreen = true;

void main() {
  if (WebRTC.platformIsDesktop) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) async {
    // Muestra el splash screen durante 5 segundos
    await Future.delayed(Duration(seconds: 5));

    // Después de 5 segundos, establece showSplashScreen como falso
    showSplashScreen = false;
    runApp(MyApp());
  });
}

typedef PageContentBuilder = Widget Function([
  SIPUAHelper? helper,
  Object? arguments,
]);

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
    '/config': ([SIPUAHelper? helper, Object? arguments]) =>
        ConfiguracionWidget(),
    '/contacts': ([SIPUAHelper? helper, Object? arguments]) => Contacts(helper),
    '/call_history': ([SIPUAHelper? helper, Object? arguments]) =>
        CallHistory(helper),
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

    // Esperar hasta que se cumplan los 5 segundos o hasta que se obtenga la respuesta
    await Future.wait([
      Future.delayed(Duration(seconds: 5)),
      Future.value(validatePreference(_preferences)),
    ]);

    // Comprobar si se obtuvo la respuesta antes de los 5 segundos
    if (validatePreference(_preferences)) {
      return '/home';
    } else {
      return '/register';
    }
  }

  bool validatePreference(SharedPreferences preferences) {
    return preferences.containsKey('dominio') &&
        preferences.containsKey('password') &&
        preferences.containsKey('extension');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yaco Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'Roboto',
      ),
      home: FutureBuilder<String>(
        future: initialRoute(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Mientras el futuro está en progreso, muestra una pantalla de carga
            //return CircularProgressIndicator();
            return Scaffold(
              body: Image.asset(
                'assets/images/splash_bg.webp',
                fit: BoxFit.cover,
              ),
            );
          } else if (snapshot.hasError) {
            // Si ocurre un error durante la obtención del futuro envia a register
            return Navigator(
              initialRoute: '/register',
              onGenerateRoute: _onGenerateRoute,
            );
          } else {
            // Una vez que el futuro se completa con éxito establece la ruta inicial
            return WillPopScope(
              onWillPop: () async {
                // Muestra una ventana emergente de confirmación
                bool confirmExit = await showDialog(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: Text('Cerrar aplicación'),
                    content: Text(
                        '¿Estás seguro de que deseas cerrar la aplicación?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('Aceptar'),
                      ),
                    ],
                  ),
                );

                // Si confirmExit es verdadero, se cierra la aplicación
                return confirmExit;
              },
              child: Navigator(
                initialRoute: snapshot.data,
                onGenerateRoute: _onGenerateRoute,
              ),
            );
          }
        },
      ),
    );
  }
}

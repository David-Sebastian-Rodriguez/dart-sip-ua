import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class AboutWidget extends StatefulWidget {
  @override
  _AboutWidgetState createState() => _AboutWidgetState();
}

class _AboutWidgetState extends State<AboutWidget> {
  bool idiomEs = true;
  late SharedPreferences _preferences;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _preferences = await SharedPreferences.getInstance();

    if (!_preferences.containsKey('lang')) {
      _preferences.setString('lang', 'es');
    }

    idiomEs = _preferences.getString('lang') == 'es';

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text(
          idiomEs ? 'Sobre nosotros' : "About",
          style: TextStyle(
            color: Colors.white, // Cambia el color del texto aquí
          ),
        ),
      ),
      body: Scaffold(
        backgroundColor: Colors.white, // Color de fondo del Scaffold
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Center(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48.0, 50.0, 48.0, 50.0),
                    child: Center(
                      child: Image.asset(
                        'assets/images/company_logo.webp',
                        width: 250,
                      ),
                    ),
                  ),
                  /* Text(
                    'About',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ), */
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      idiomEs
                          ? '''Empresa Colombiana con experiencia en diseño, desarrollo e implementación de soluciones de software para telecomunicaciones. Comunicaciones unificadas, atención omnicanal, chatbots, chatcenter, clicktovideo, Webphone para Google Workspace, IVR, grabación de pantallas, grabación para Microsoft Teams y Webex Teams, grabación de audiencias, transcripción automática y relatoría. Más información:'''
                          : 'Colombian company with experience in design, development and implementation of software solutions for telecommunications. Unified communications, omnichannel service, chatbots, chatcenter, clicktovideo, Webphone for Google Workspace, IVR, screen recording, recording for Microsoft Teams and Webex Teams, audience recording, automatic transcription and rapporteur. More information:',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    'www.calltechsa.com',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    '© 2024 Calltech S.A',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    idiomEs
                        ? 'Todos los derechos reservados.'
                        : 'All rights reserved.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'V-1.0.6',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

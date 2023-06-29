import 'package:flutter/material.dart';

class AboutWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(
          "About",
          style: TextStyle(
            color: Colors.white, // Cambia el color del texto aquí
          ),
        ),
      ),
      body: Scaffold(
        backgroundColor: Colors.black87, // Color de fondo del Scaffold
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Center(
              child: Column(
                children: <Widget>[
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
                      'Empresa Colombiana con experiencia en diseño, desarrollo e implementación de soluciones de software para telecomunicaciones. Comunicaciones unificadas, atención omnicanal, chatbots, chatcenter, clicktovideo, Webphone para Google Workspace, IVR, grabación de pantallas, grabación para Microsoft Teams y Webex Teams, grabación de audiencias, transcripción automática y relatoría. Más información:',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'www.calltechsa.com',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    '© 2023 Calltech S.A',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Todos los derechos reservados.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfiguracionWidget extends StatefulWidget {
  @override
  _ConfiguracionWidgetState createState() => _ConfiguracionWidgetState();
}

class _ConfiguracionWidgetState extends State<ConfiguracionWidget> {
  late String idiomaSeleccionado = 'español';
  late SharedPreferences _preferences;
  bool _preferencesInitialized = false;

  @override
  initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _preferences = await SharedPreferences.getInstance();
    _preferencesInitialized = true;

    if (_preferences.getString('lang') == "en") {
      idiomaSeleccionado = 'inglés';
    }

    print(_preferences.getString('lang......................'));

    setState(() {});
  }

  bool isEs() {
    if (_preferencesInitialized == false) {
      return true;
    } else {
      return _preferences.getString('lang')! == 'es';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(
          "Configuración",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Scaffold(
        backgroundColor: Colors.black87,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Center(
              child: Column(
                children: <Widget>[
                  Text(
                    'Configuración',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  ListTile(
                    title: Text(
                      'Idioma',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  RadioListTile<String>(
                    title: Text(
                      'Español',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    value: 'español',
                    groupValue: idiomaSeleccionado,
                    onChanged: (value) {
                      setState(() {
                        idiomaSeleccionado = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(
                      'Inglés',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    value: 'inglés',
                    groupValue: idiomaSeleccionado,
                    onChanged: (value) {
                      if (value == 'español') {
                        _preferences.setString('lang', 'es');
                      } else {
                        _preferences.setString('lang', 'en');
                      }
                      print(_preferences.getString('lang').toString() +
                          '.................');
                      setState(() {
                        idiomaSeleccionado = value!;
                      });
                    },
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

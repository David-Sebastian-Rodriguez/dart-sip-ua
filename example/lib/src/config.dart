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
  bool idiomEs = true;

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

    idiomEs = _preferences.getString('lang') == 'es';
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
        backgroundColor: Colors.red,
        title: Text(
          idiomEs ? 'Configuración' : 'Setting',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Center(
              child: Column(
                children: <Widget>[
                  Text(
                    idiomEs ? 'Configuración' : 'Setting',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20),
                  ListTile(
                    title: Text(
                      idiomEs ? 'Idioma' : 'Language',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  RadioListTile<String>(
                    title: Text(
                      idiomEs ? 'Español' : 'Spanish',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                    value: 'español',
                    groupValue: idiomaSeleccionado,
                    onChanged: (value) {
                      _preferences.setString('lang', 'es');
                      idiomEs = _preferences.getString('lang') == 'es';
                      setState(() {
                        idiomaSeleccionado = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(
                      idiomEs ? 'Inglés' : 'English',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                    value: 'inglés',
                    groupValue: idiomaSeleccionado,
                    onChanged: (value) {
                      _preferences.setString('lang', 'en');
                      idiomEs = _preferences.getString('lang') == 'es';
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

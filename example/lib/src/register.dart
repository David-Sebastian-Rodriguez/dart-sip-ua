import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sip_ua/sip_ua.dart';

class RegisterWidget extends StatefulWidget {
  final SIPUAHelper? _helper;
  RegisterWidget(this._helper, {Key? key}) : super(key: key);
  @override
  _MyRegisterWidget createState() => _MyRegisterWidget();
}

class _MyRegisterWidget extends State<RegisterWidget>
    implements SipUaHelperListener {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _domainController = TextEditingController();
  final TextEditingController _extensionController = TextEditingController();
  final Map<String, String> _wsExtraHeaders = {
    // 'Origin': ' https://tryit.jssip.net',
    // 'Host': 'tryit.jssip.net:10443'
  };
  late SharedPreferences _preferences;
  late RegistrationState _registerState;

  bool _passwordVisible = false;

  SIPUAHelper? get helper => widget._helper;

  @override
  initState() {
    super.initState();
    _registerState = helper!.registerState;
    helper!.addSipUaHelperListener(this);
    _loadSettings();
  }

  @override
  deactivate() {
    super.deactivate();
    helper!.removeSipUaHelperListener(this);
  }

  void _loadSettings() async {
    const extencion1 = '901';
    //const extencion2 = '561';
    const extencion = extencion1;
    _preferences = await SharedPreferences.getInstance();
    // codigo para hacer que al inicio se borren los datos guardados de autenticacion
    //_preferences.clear();
    setState(() {
      _domainController.text =
          _preferences.getString('dominio') ?? 'yaco.calltechsa.com';
      _passwordController.text =
          _preferences.getString('password') ?? 'Ext${extencion}Calltech*';
      _extensionController.text =
          _preferences.getString('extension') ?? extencion;
    });
    if (validatePreference(_preferences) &&
        _registerState.state != RegistrationStateEnum.REGISTERED) _sendAuth();
  }

  bool validatePreference(SharedPreferences preferences) {
    return preferences.containsKey('dominio') &&
        preferences.containsKey('password') &&
        preferences.containsKey('extension');
  }

  void _saveSettings() {
    _preferences.setString('dominio', _domainController.text);
    _preferences.setString('password', _passwordController.text);
    _preferences.setString('extension', _extensionController.text);
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    setState(() {
      _registerState = state;
    });
    if (_registerState.state == RegistrationStateEnum.REGISTERED) {
      _saveSettings();
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _alert(BuildContext context, String alertFieldName) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$alertFieldName esta vacio'),
          content: Text('Por favor ingrese $alertFieldName!'),
          actions: <Widget>[
            TextButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _handleSave(BuildContext context) {
    if (_domainController.text == '') {
      _alert(context, "Dominio");
    } else if (_passwordController.text == '') {
      _alert(context, "Contraseña");
    } else if (_extensionController.text == '') {
      _alert(context, "Extensión");
    } else {
      _sendAuth();
    }
  }

  void _sendAuth() {
    UaSettings settings = UaSettings();

    settings.webSocketUrl = 'wss://${_domainController.text}:8534';
    settings.webSocketSettings.extraHeaders = _wsExtraHeaders;
    settings.webSocketSettings.allowBadCertificate = true;
    //settings.webSocketSettings.userAgent = 'Dart/2.8 (dart:io) for OpenSIPS.';

    settings.uri = 'sip:${_extensionController.text}@143.244.209.136';
    settings.authorizationUser = _extensionController.text;
    settings.password = _passwordController.text;
    settings.userAgent = 'Dart SIP Client v1.0.0';
    settings.dtmfMode = DtmfMode.RFC2833;

    helper!.start(settings);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        /* appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("SIP Account"),
      ), */
        body: SingleChildScrollView(
          child: Container(
            color: Colors.white,
            child: DefaultTextStyle(
              style: TextStyle(color: Colors.black),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48.0, 150.0, 48.0, 50.0),
                    child: Center(
                      child: Image.asset(
                        'assets/images/company_logo.webp',
                        width: 250,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48.0, 25.0, 48.0, 0),
                    child: TextFormField(
                      controller: _domainController,
                      keyboardType: TextInputType.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Dominio',
                        hintStyle: TextStyle(color: Colors.black),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors
                                  .black), // Color de la línea inferior deseado
                        ),
                        contentPadding: EdgeInsets.all(10.0),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48.0, 50.0, 48.0, 0),
                    child: TextFormField(
                      controller: _extensionController,
                      keyboardType: TextInputType.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Extensión',
                        hintStyle: TextStyle(
                          color: Colors.black,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.black,
                          ), // Color de la línea inferior deseado
                        ),
                        contentPadding: EdgeInsets.all(
                          10.0,
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48.0, 50.0, 48.0, 0),
                    child: TextFormField(
                      controller: _passwordController,
                      keyboardType: TextInputType.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                      ),
                      obscureText:
                          !_passwordVisible, // Oculta o muestra el texto según el valor de _passwordVisible
                      decoration: InputDecoration(
                        hintText: 'Contraseña',
                        hintStyle: TextStyle(
                          color: Colors.black,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.black,
                          ),
                        ),
                        contentPadding: EdgeInsets.all(10.0),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisible =
                                  !_passwordVisible; // Cambia el estado de visibilidad de la contraseña
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0.0, 50.0, 0.0, 0.0),
                    child: Container(
                      height: 48.0,
                      width: 160.0,
                      child: MaterialButton(
                        child: Text(
                          'Register',
                          style: TextStyle(fontSize: 16.0, color: Colors.white),
                        ),
                        color: Colors.red,
                        onPressed: () => _handleSave(context),
                      ),
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

  @override
  void callStateChanged(Call call, CallState state) {
    //NO OP
  }

  @override
  void transportStateChanged(TransportState state) {}

  @override
  void onNewMessage(SIPMessageRequest msg) {
    // NO OP
  }

  @override
  void onNewNotify(Notify ntf) {
    // NO OP
  }
}

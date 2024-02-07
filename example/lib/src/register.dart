import 'dart:async';

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
  final TextEditingController _iPController = TextEditingController();
  final TextEditingController _extensionController = TextEditingController();
  final Map<String, String> _wsExtraHeaders = {
    // 'Origin': ' https://tryit.jssip.net',
    // 'Host': 'tryit.jssip.net:10443'
  };
  late SharedPreferences _preferences;
  late RegistrationState _registerState;

  bool checkIp = false;

  bool _passwordVisible = false;

  SIPUAHelper? get helper => widget._helper;

  bool isActiverTimer = false;

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
    //const extencion1 = '901';
    //const extencion2 = '561';
    //const extencion = extencion1;
    _preferences = await SharedPreferences.getInstance();
    // codigo para hacer que al inicio se borren los datos guardados de autenticacion
    //_preferences.clear();

    /* setState(() {
      _domainController.text =
          _preferences.getString('dominio') ?? 'yaco.calltechsa.com';
      _passwordController.text =
          _preferences.getString('password') ?? 'Ext${extencion}Calltech*';
      _extensionController.text =
          _preferences.getString('extension') ?? extencion;
    }); */

    setState(() {
      _domainController.text = _preferences.getString('dominio') ?? '';
      _iPController.text = _preferences.getString('IP') ?? '';
      checkIp = _preferences.getString('IPCheck') == 'true';
      _extensionController.text = _preferences.getString('extension') ?? '';
      _passwordController.text = _preferences.getString('password') ?? '';
    });

    if (validatePreference(_preferences) &&
        _registerState.state != RegistrationStateEnum.REGISTERED) _sendAuth();
  }

  bool validatePreference(SharedPreferences preferences) {
    return preferences.containsKey('dominio') &&
        preferences.containsKey('password') &&
        preferences.containsKey('extension') &&
        preferences.containsKey('IPCheck') &&
        preferences.containsKey('IP');
  }

  void _saveSettings() {
    _preferences.setString('dominio', _domainController.text);
    _preferences.setString('IP', _iPController.text);
    _preferences.setString('IPCheck', checkIp.toString());
    _preferences.setString('password', _passwordController.text);
    _preferences.setString('extension', _extensionController.text);
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    setState(() {
      _registerState = state;
    });
    print('intento de registro aaaaaaaaaaaaaaaaaa');
    if (_registerState.state == RegistrationStateEnum.REGISTERED) {
      _saveSettings();
      isActiverTimer = false;
      Navigator.pushReplacementNamed(context, '/home');
    } else if (isActiverTimer) {
      print('fallo aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
      isActiverTimer = false;
      _alertFail(context);
    }
  }

  void _alertFail(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error al iniciar sesión'),
          content: Text(
              'Error al intentar iniciar sesión. Por favor, verifique los campos Dominio, Usuario y Contraseña y de ser necesario añada una direccion IP y Verifíquela.'),
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
      isActiverTimer = false;
      _alert(context, "Dominio");
    } else if (_passwordController.text == '') {
      isActiverTimer = false;
      _alert(context, "Contraseña");
    } else if (_extensionController.text == '') {
      isActiverTimer = false;
      _alert(context, "Extensión");
    } else if (_iPController.text == '' && checkIp) {
      isActiverTimer = false;
      _alert(context, "IP");
    } else {
      _sendAuth();
    }
  }

  void _sendAuth() {
    UaSettings settings = UaSettings();

    String iP = _domainController.text;
    String dominio = _domainController.text;

    if (_iPController.text != "" && checkIp) {
      iP = _iPController.text;
      dominio = _iPController.text;
    }

    settings.webSocketUrl = 'wss://$dominio:8534';
    settings.webSocketSettings.extraHeaders = _wsExtraHeaders;
    settings.webSocketSettings.allowBadCertificate = true;
    //settings.webSocketSettings.userAgent = 'Dart/2.8 (dart:io) for OpenSIPS.';

    /*switch (_domainController.text) {
      case 'yaco.calltechsa.com':
        Ip = '143.244.209.136';
        break;
      case 'yaco-staging.calltechsa.com':
        Ip = '192.168.0.184';
        break;
      case 'yaco-dev.calltechsa.com':
        Ip = '167.172.16.183';
        break;
      default:
    } */

    //settings.uri = 'sip:${_extensionController.text}@143.244.209.136';
    //settings.uri = 'sip:${_extensionController.text}@$Ip';
    settings.uri = 'sip:${_extensionController.text}@$iP';
    print('${settings.uri} aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');

    settings.authorizationUser = _extensionController.text;
    settings.password = _passwordController.text;
    settings.userAgent = 'Dart SIP Client v1.0.0';
    settings.dtmfMode = DtmfMode.RFC2833;

    helper!.start(settings);

    isActiverTimer = true;

    Timer(Duration(seconds: 5), () {
      if (isActiverTimer) {
        _alertFail(context);
      }
    });
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
                    padding: const EdgeInsets.fromLTRB(48.0, 25.0, 48.0, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width:
                              50, // Ancho del contenedor que contiene Checkbox y Text
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: checkIp,
                                onChanged: (newValue) {
                                  // Cambiar el estado del checkbox
                                  setState(() {
                                    checkIp = newValue!;
                                  });
                                },
                              ),
                              SizedBox(
                                height:
                                    2, // Espacio entre el Checkbox y el Text "IP"
                              ),
                              Text(
                                'IP',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                            width:
                                24), // Ajuste el espacio entre el Checkbox y el TextFormField
                        Expanded(
                          child: checkIp
                              ? TextFormField(
                                  controller: _iPController,
                                  keyboardType: TextInputType.text,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    hintText: 'IP',
                                    hintStyle: TextStyle(color: Colors.black),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.black,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.all(10.0),
                                    border: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(), // Oculta el TextFormField si checkIp es falso
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48.0, 10.0, 48.0, 0),
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

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:http/http.dart' as http;

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
  //final TextEditingController _iPController = TextEditingController();
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

  Map<String, dynamic> dataAccess = {
    'domain': '',
    'sipDomain': '',
    'emExtensionNumber': '',
    'emPassword': '',
    'aboutUsLink': '',
  };

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
      //_iPController.text = _preferences.getString('IP') ?? '';
      //checkIp = _preferences.getString('IPCheck') == 'true';
      _extensionController.text = _preferences.getString('extension') ?? '';
      _passwordController.text = _preferences.getString('password') ?? '';
    });

    if (validatePreference(_preferences) &&
        _registerState.state != RegistrationStateEnum.REGISTERED) {
      _sendAuth({
        'domain': _preferences.getString('dominio'),
        'sipDomain': _preferences.getString('dominioIP'),
        'emExtensionNumber': '',
        'emPassword': '',
        'aboutUsLink': '',
      });
    }
  }

  bool validatePreference(SharedPreferences preferences) {
    return preferences.containsKey('dominio') &&
        preferences.containsKey('password') &&
        preferences.containsKey('extension') &&
        //preferences.containsKey('IPCheck') &&
        preferences.containsKey('dominioIP');
  }

  void _saveSettings() {
    _preferences.setString('dominio', _domainController.text);
    _preferences.setString('dominioIP', dataAccess['sipDomain']);
    //_preferences.setString('IPCheck', checkIp.toString());
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
      isActiverTimer = false;
      Navigator.pushReplacementNamed(context, '/home');
    } else if (isActiverTimer) {
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
              'Error al intentar iniciar sesión. Por favor, verifique los campos, Dominio, Usuario y Contraseña.'),
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
          content: Text('Por favor ingrese $alertFieldName !'),
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

  void _handleSave(BuildContext context) async {
    List<String> messageArray = [];

    if (_domainController.text == '') {
      messageArray.add("dominio");
    }

    if (_passwordController.text == '') {
      messageArray.add("contraseña");
    }

    if (_extensionController.text == '') {
      messageArray.add("extensión");
    }

    /* if (_iPController.text == '' && checkIp) {
      messageArray.add("dirección IP");
    } */

    if (messageArray.isNotEmpty) {
      isActiverTimer = false;

      String message = "";

      for (int i = 0; i < messageArray.length; i++) {
        if (i == 0) {
          message += messageArray[i];
        } else if (i == messageArray.length - 1) {
          message += " y " + messageArray[i];
        } else {
          message += ", " + messageArray[i];
        }
      }

      _alert(context, message);
    } else {
      Map<String, dynamic>? res = await _getDataAccess();
      if (res != null) {
        dataAccess = res;
        _sendAuth(dataAccess);
      } else {
        _alertFail(context);
      }
    }
  }

  Future<Map<String, dynamic>?> _getDataAccess() async {
    // URL de la solicitud POST
    final String url =
        'https://${_domainController.text}/web/index.php?r=api/auth/login';
    //'http://${_domainController.text}:8091/web/index.php?r=api/auth/login';

    print(url);

    // Cuerpo de la solicitud POST
    Map<String, dynamic> body = {
      "uid": _extensionController.text,
      "password": _passwordController.text,
      "device_id": "mnedr453mfnbvslestQrRes",
      "force_login": "1"
    };

    // Convierte el cuerpo a formato JSON
    String jsonBody = json.encode(body);

    try {
      // Realiza la solicitud POST
      http.Response response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonBody,
      );

      // Verifica el código de estado de la respuesta
      if (response.statusCode == 200) {
        // Procesa la respuesta exitosa
        Map<String, dynamic> responseData = json.decode(response.body);
        int status = responseData['status'];

        if (status == 200) {
          Map<String, dynamic> data = responseData['data'];
          String domain = data['webrtc_url'];
          String sipDomain = data['webrtc_sip_domain'];
          String emExtensionNumber = data['em_extension_number'];
          String emPassword = data['em_password'];
          String aboutUsLink = data['about_us_link'];

          Map<String, dynamic> res = {
            'domain': domain,
            'sipDomain': sipDomain,
            'emExtensionNumber': emExtensionNumber,
            'emPassword': emPassword,
            'aboutUsLink': aboutUsLink,
          };

          print(res);
          return res;
        }
      } else {
        print('error');
      }
    } catch (error) {
      print(error);
      print('error web service');
      return null;
    }
    print('eerror');

    return null;
  }

  void _sendAuth(Map<String, dynamic> dataAccess) {
    UaSettings settings = UaSettings();

    String dominio = dataAccess['domain'];
    String dominioSip = dataAccess['sipDomain'];

    print('$dominioSip aaaaaaaaaaaaaaaaaaaa');

    /* String iP = _domainController.text;

    if (_iPController.text != "" && checkIp) {
      iP = _iPController.text;
      dominio = _iPController.text;
    }
    */

    //settings.webSocketUrl = 'wss://$dominio:8534';
    settings.webSocketUrl = dominio;
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
    settings.uri = 'sip:${_extensionController.text}@$dominioSip';
    //settings.uri = 'sip:${_extensionController.text}@$dominioSip';

    settings.authorizationUser = _extensionController.text;
    settings.password = _passwordController.text;
    settings.userAgent = 'Dart SIP Client v1.0.0';
    settings.dtmfMode = DtmfMode.RFC2833;

    helper!.start(settings);

    isActiverTimer = true;

    Timer(Duration(seconds: 8), () {
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
                    padding: const EdgeInsets.fromLTRB(48.0, 180.0, 48.0, 50.0),
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
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors
                                  .red), // Color de la línea cuando está seleccionado
                        ),
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
                  /*Padding(
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
                  ), */
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48.0, 35.0, 48.0, 0),
                    child: TextFormField(
                      controller: _extensionController,
                      keyboardType: TextInputType.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors
                                  .red), // Color de la línea cuando está seleccionado
                        ),
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
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors
                                  .red), // Color de la línea cuando está seleccionado
                        ),
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
                          'Registrar',
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

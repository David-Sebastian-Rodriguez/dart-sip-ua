import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sip_ua/sip_ua.dart';

import 'widgets/action_button.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:audioplayers/audioplayers.dart';

class DialPadWidget extends StatefulWidget {
  final SIPUAHelper? _helper;
  DialPadWidget(this._helper, {Key? key}) : super(key: key);
  @override
  _MyDialPadWidget createState() => _MyDialPadWidget();
}

class _MyDialPadWidget extends State<DialPadWidget>
    with WidgetsBindingObserver
    implements SipUaHelperListener {
  String? _dest;
  String? _ext;
  String? _dominio;
  SIPUAHelper? get helper => widget._helper;
  TextEditingController? _textController;
  late SharedPreferences _preferences;
  bool _preferencesInitialized = false;
  bool idiomEs = true;

  bool isInCalling = false;

  bool isLogOut = false;

  late String _wsUriController;
  late String _passwordController;
  late String _authorizationUserController;
  late String _callTone;

  String? receivedMsg;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void configureLocalNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  AppLifecycleState? _appState;
  late RegistrationState _registerState;

  AudioCache audioCache = AudioCache();
  AudioPlayer player = AudioPlayer();

  @override
  initState() {
    super.initState();
    receivedMsg = "";
    _bindEventListeners();
    _loadSettings();
    // Add the observer.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Remove the observer
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // These are the callbacks
    switch (state) {
      case AppLifecycleState.resumed:
        if (player.state == PlayerState.PLAYING) {
          stopSound();
        }
        _appState = state;
        Navigator.pushNamed(context, '/help');
        Future.delayed(Duration(milliseconds: 200), () {
          Navigator.pop(context);
        });
        break;
      case AppLifecycleState.inactive:
        // widget is inactive
        _appState = state;
        break;
      case AppLifecycleState.paused:
        // widget is paused
        _appState = state;
        break;
      case AppLifecycleState.detached:
        // widget is detached
        _appState = state;
        break;
    }
  }

  Future<void> _loadSettings() async {
    _preferences = await SharedPreferences.getInstance();
    _registerState = helper!.registerState;
    _preferencesInitialized = true;
    if (_registerState.state != RegistrationStateEnum.REGISTERED) {
      _sendAuth();
    }
    //_dest = _preferences.getString('dest') ?? '8888';
    _dest = _preferences.getString('dest') ?? '';
    _ext = _preferences.getString('extension') ?? 'None';
    _dominio = _preferences.getString('dominio') ?? '';
    _textController = TextEditingController(text: _dest);
    _textController!.text = _dest!;
    if (_preferences.getString('tone') == null) {
      await _preferences.setString('tone', 'sounds/call_sound_1.mp3');
    }
    _callTone = _preferences.getString('tone') ?? 'sounds/call_sound_1.mp3';

    if (!_preferences.containsKey('lang')) {
      _preferences.setString('lang', 'es');
    }
    idiomEs = _preferences.getString('lang') == 'es';

    setState(() {});
  }

  void isEs() {
    if (_preferencesInitialized == false) {
      idiomEs = true;
    } else {
      idiomEs = _preferences.getString('lang') == 'es';
    }

    setState(() {});
  }

  Future<void> _cleanAuth() async {
    //await _preferences.remove('dominio');
    await _preferences.remove('password');
    await _preferences.remove('extension');
  }

  void _sendAuth() {
    setState(
      () {
        _wsUriController = 'wss://${_preferences.getString('dominio')}:8534';
        _passwordController = _preferences.getString('password')!;
        _authorizationUserController = _preferences.getString('extension')!;
      },
    );

    final Map<String, String> _wsExtraHeaders = {
      // 'Origin': ' https://tryit.jssip.net',
      // 'Host': 'tryit.jssip.net:10443'
    };

    UaSettings settings = UaSettings();

    settings.webSocketUrl = _wsUriController;
    settings.webSocketSettings.extraHeaders = _wsExtraHeaders;
    settings.webSocketSettings.allowBadCertificate = true;
    //settings.webSocketSettings.userAgent = 'Dart/2.8 (dart:io) for OpenSIPS.';
    settings.uri =
        'sip:$_authorizationUserController@${_preferences.getString('dominioIP')}';

    settings.authorizationUser = _authorizationUserController;
    settings.password = _passwordController;
    settings.userAgent = 'Dart SIP Client v1.0.0';
    settings.dtmfMode = DtmfMode.RFC2833;

    helper!.start(settings);
  }

  void playSound() async {
    player = await audioCache.loop(_callTone);
  }

  void stopSound() {
    player.stop();
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    setState(
      () {
        _registerState = state;
      },
    );
    if (_registerState.state != RegistrationStateEnum.REGISTERED) {
      //Codigo en caso de que el registro falle
      if (!isLogOut) _alert(context, '');
    }
  }

  void _bindEventListeners() {
    helper!.addSipUaHelperListener(this);
  }

  Future<Widget?> _handleCall(BuildContext context,
      [bool voiceOnly = false]) async {
    if (helper!.registerState.state != RegistrationStateEnum.REGISTERED) {
      _alert(context, '');
      return null;
    }
    var dest = _textController?.text;
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      await Permission.microphone.request();
      await Permission.camera.request();
    }
    if (dest == null || dest.isEmpty) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text(
                  idiomEs ? 'Número no especificado.' : 'Target is empty.'),
              content: Text(idiomEs
                  ? '¡Por favor, ingresa una URI SIP o un nombre de usuario!'
                  : 'Please enter a SIP URI or username!'),
              actions: <Widget>[
                TextButton(
                    child: Text('Ok'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    })
              ]);
        },
      );
      return null;
    }

    final mediaConstraints = <String, dynamic>{'audio': true, 'video': true};

    MediaStream mediaStream;

    if (kIsWeb && !voiceOnly) {
      mediaStream =
          await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
      mediaConstraints['video'] = false;
      MediaStream userStream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      mediaStream.addTrack(userStream.getAudioTracks()[0], addToNative: true);
    } else {
      mediaConstraints['video'] = !voiceOnly;
      mediaStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    }

    var destUri = 'sip:$dest@143.244.209.136';

    helper!.call(
      destUri,
      voiceonly: voiceOnly,
      mediaStream: mediaStream,
    );
    return null;
  }

  void _alert(BuildContext context, String alertFieldName) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(idiomEs ? 'Error de registro' : 'Registration Error'),
          content: Text(idiomEs
              ? 'El usuario no está registrado en este momento.'
              : 'The user is not registered at the moment'),
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

  void _handleBackSpace([bool deleteAll = false]) {
    var text = _textController!.text;
    if (text.isNotEmpty) {
      setState(
        () {
          text = deleteAll ? '' : text.substring(0, text.length - 1);
          _textController!.text = text;
        },
      );
    }
  }

  void _handleNum(String number) {
    setState(() {
      _textController!.text += number;
    });
  }

  List<Widget> _buildNumPad() {
    var labels = [
      [
        {'1': ''},
        {'2': 'abc'},
        {'3': 'def'}
      ],
      [
        {'4': 'ghi'},
        {'5': 'jkl'},
        {'6': 'mno'}
      ],
      [
        {'7': 'pqrs'},
        {'8': 'tuv'},
        {'9': 'wxyz'}
      ],
      [
        {'*': ''},
        {'0': '+'},
        {'#': ''}
      ],
    ];

    return labels
        .map(
          (row) => Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row
                  .map(
                    (label) => ActionButton(
                      title: label.keys.first,
                      subTitle: label.values.first,
                      onPressed: () => _handleNum(label.keys.first),
                      number: true,
                    ),
                  )
                  .toList(),
            ),
          ),
        )
        .toList();
  }

  List<Widget> _buildDialPad() {
    return [
      Container(
        width: 360,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 360,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.all(10.0),
                margin: EdgeInsets.symmetric(vertical: 30),
                child: Text(
                  _textController?.text.toString() ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                  ),
                ),
                /* child: TextField(
                  keyboardType: TextInputType.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, color: Colors.white),
                  decoration: InputDecoration(border: InputBorder.none),
                  controller: _textController,
                ), */
              ),
            ),
          ],
        ),
      ),
      Container(
        width: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildNumPad(),
        ),
      ),
      Container(
        width: 300,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ActionButton(
                  icon: Icons.videocam,
                  fillColor: Colors.green,
                  onPressed: () => _handleCall(context)),
              ActionButton(
                icon: Icons.dialer_sip,
                fillColor: Colors.green,
                onPressed: () => _handleCall(context, true),
              ),
              ActionButton(
                icon: Icons.keyboard_arrow_left,
                fillColor: Colors.red,
                onPressed: () => _handleBackSpace(),
                onLongPress: () => _handleBackSpace(true),
              ),
            ],
          ),
        ),
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text(
          idiomEs ? "Marcador" : "Dialer",
          style: TextStyle(color: Colors.white),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.red,
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              accountName: Padding(
                padding: EdgeInsets.only(top: 0.0, left: 15),
                child: Text(
                  _ext ?? '',
                  style: TextStyle(fontSize: 25, color: Colors.white),
                ),
              ),
              accountEmail: Padding(
                padding: EdgeInsets.only(top: 0.0, left: 15),
                child: Text(
                  (_dominio ?? '').split('.')[0],
                  style: TextStyle(fontSize: 15, color: Colors.white),
                ),
              ),
              currentAccountPicture: Padding(
                padding: EdgeInsets.only(top: 0.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage('assets/images/avatar.png'),
                  radius: 100,
                ),
              ),
            ),
            ListTile(
              title: Text(
                idiomEs
                    ? (() {
                        switch (helper!.registerState.state) {
                          case RegistrationStateEnum.NONE:
                            return 'Error';
                          case RegistrationStateEnum.REGISTRATION_FAILED:
                            return 'Fallo en el registro';
                          case RegistrationStateEnum.REGISTERED:
                            return 'Registrado';
                          case RegistrationStateEnum.UNREGISTERED:
                            return 'No registrado';
                          default:
                            return 'Desconocido';
                        }
                      })()
                    : (() {
                        switch (helper!.registerState.state) {
                          case RegistrationStateEnum.NONE:
                            return 'None';
                          case RegistrationStateEnum.REGISTRATION_FAILED:
                            return 'Registration failed';
                          case RegistrationStateEnum.REGISTERED:
                            return 'Registered';
                          case RegistrationStateEnum.UNREGISTERED:
                            return 'Unregistered';
                          default:
                            return 'Unknown';
                        }
                      })(),
                style: TextStyle(color: Colors.white),
              ),
              leading: Image.asset(
                helper!.registerState.state == RegistrationStateEnum.REGISTERED
                    ? 'assets/images/led_connected.png'
                    : 'assets/images/led_disconnected.png',
                width: 25,
              ),
              onTap: () {
                _sendAuth();
              },
            ),
            ListTile(
                title: Text(idiomEs ? 'Contactos' : 'Contacts',
                    style: TextStyle(color: Colors.white)),
                leading:
                    Icon(Icons.contact_phone, color: Colors.white, size: 25),
                onTap: () {
                  Navigator.pushNamed(context, '/contacts');
                }),
            ListTile(
              title: Text(idiomEs ? 'Historial de llamadas' : 'Call History',
                  style: TextStyle(color: Colors.white)),
              leading: Icon(Icons.history, color: Colors.white, size: 25),
              onTap: () {
                Navigator.pushNamed(context, '/call_history');
              },
            ),
            ListTile(
              title: Text(idiomEs ? 'Sobre nosotros' : 'About',
                  style: TextStyle(color: Colors.white)),
              leading: Icon(Icons.info, color: Colors.white, size: 25),
              onTap: () {
                Navigator.pushNamed(context, '/about');
              },
            ),
            ListTile(
              title: Text(idiomEs ? 'Configuración' : 'Setting',
                  style: TextStyle(color: Colors.white)),
              leading: Icon(Icons.settings, color: Colors.white, size: 25),
              onTap: () {
                Navigator.pushNamed(context, '/config').then((result) {
                  setState(() {
                    idiomEs = _preferences.getString('lang') == 'es';
                  });
                });
              },
            ),
            ListTile(
              title: Text(idiomEs ? 'Cerrar sesión' : 'Logout',
                  style: TextStyle(color: Colors.white)),
              leading: Icon(Icons.logout, color: Colors.white, size: 25),
              onTap: () async {
                await _cleanAuth();
                //_preferences.clear();
                isLogOut = true;
                helper!.stop();
                Navigator.pushNamed(context, '/register');
              },
            ),
          ],
        ),
      ),
      body: Container(
        child: DefaultTextStyle(
          style: TextStyle(color: Colors.white),
          child: Align(
            alignment: Alignment(0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildDialPad(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void transportStateChanged(TransportState state) {}

  @override
  void callStateChanged(Call call, CallState callState) {
    if (callState.state == CallStateEnum.CALL_INITIATION && !isInCalling) {
      isInCalling = true;
      Navigator.pushNamed(context, '/callscreen', arguments: call);
      var dest = _textController?.text;
      _preferences.setString('dest', dest!);
      if (_appState == AppLifecycleState.paused) {
        _showIncomingCallNotification();
      }
    }
    if (callState.state == CallStateEnum.FAILED) {
      //si falla la llamada se rechaza, o se cuelga antes de que el otro conteste
      isInCalling = false;
      if (_appState == AppLifecycleState.paused) {
        //si el que llama cuelga cuando el llamado tiene la app en segundo plano
        stopSound();
        flutterLocalNotificationsPlugin.cancel(0);
        Navigator.of(context).pop();
        isInCalling = false;
      }
    }
    if (callState.state == CallStateEnum.ENDED) {
      //ocurre cuando la llamada se acepta y luego se cuelga
      isInCalling = false;
    }
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    //Save the incoming message to DB
    String? msgBody = msg.request.body as String?;
    setState(
      () {
        receivedMsg = msgBody;
      },
    );
  }

  @override
  void onNewNotify(Notify ntf) {}

  void _showIncomingCallNotification() async {
    if (player.state != PlayerState.PLAYING) {
      playSound();
    }
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('incoming_call_channel', 'Incoming Call',
            channelDescription: 'Channel for incoming call notifications',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false,
            icon: '@mipmap/ic_launcher');
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin
        .show(
      0,
      'Llamada entrante',
      'Tienes una llamada',
      platformChannelSpecifics,
    )
        .catchError(
      (onError) {
        print(onError);
      },
    );
  }
}

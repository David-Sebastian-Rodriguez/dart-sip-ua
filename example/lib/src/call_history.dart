import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/foundation.dart';

class CallHistory extends StatefulWidget {
  final SIPUAHelper? _helper;
  CallHistory(this._helper, {Key? key}) : super(key: key);

  @override
  _CallHistoryState createState() => _CallHistoryState();
}

class _CallHistoryState extends State<CallHistory> {
  SIPUAHelper? get helper => widget._helper;
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
          idiomEs ? "Historial de llamadas" : 'Call History',
          style: TextStyle(
            color: Colors.white, // Cambia el color del texto aquí
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: FutureBuilder<List<String>>(
          future: getCallHistory(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final callHistory = snapshot.data!;
              return ListView.builder(
                itemCount: callHistory.length,
                itemBuilder: (context, index) {
                  final callInfo = callHistory[index].split(',');
                  final phoneNumber = callInfo[0];
                  final callType = callInfo[1];
                  final dateTime = callInfo[2];

                  return Container(
                    margin: EdgeInsets.only(top: 25),
                    child: ListTile(
                      tileColor: Colors
                          .transparent, // Hacer que el fondo del ListTile sea transparente
                      leading: Icon(
                        callType == "Llamada saliente"
                            ? Icons.call_made
                            : Icons.call_received,
                        color: Colors.black, // Establecer el color del icono
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            phoneNumber,
                            style: TextStyle(
                              color:
                                  Colors.black, // Establecer el color del texto
                            ),
                          ),
                          Text(
                            DateFormat('dd-MM-yyyy')
                                .format(DateTime.parse(dateTime)),
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Colors.black, // Establecer el color del texto
                            ),
                          ),
                          Text(
                            DateFormat('h:mm:ss a')
                                .format(DateTime.parse(dateTime)),
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Colors.black, // Establecer el color del texto
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _handleCall(context, phoneNumber, true);
                                },
                                child: Icon(
                                  Icons.call,
                                  color: Colors.white,
                                  size: 25,
                                ),
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.red),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 16),
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _handleCall(context, phoneNumber);
                                },
                                child: Icon(
                                  Icons.videocam_rounded,
                                  color: Colors.white,
                                  size: 25,
                                ),
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Text('Error al cargar el historial de llamadas');
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }

  Future<List<String>> getCallHistory() async {
    final prefs = await SharedPreferences.getInstance();
    //para limpiar la lista de llamadas
    final extension = prefs.getString('extension');
    //await prefs.setStringList('call_history_$extension', []);
    final callHistory = prefs.getStringList('call_history_$extension') ?? [];
    return callHistory.reversed.toList();
  }

  Future<Widget?> _handleCall(BuildContext context, String numberPhone,
      [bool voiceOnly = false]) async {
    var dest = numberPhone;
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      await Permission.microphone.request();
      await Permission.camera.request();
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
}

import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/foundation.dart';
import 'package:shimmer/shimmer.dart';

class Contacts extends StatefulWidget {
  final SIPUAHelper? _helper;
  Contacts(this._helper, {Key? key}) : super(key: key);
  @override
  _ContactsState createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {
  List<Contact> _contacts = [];
  SIPUAHelper? get helper => widget._helper;

  @override
  void initState() {
    super.initState();
    fetchContacts();
  }

  Future<void> fetchContacts() async {
    // Verificar y solicitar los permisos
    if (await Permission.contacts.request().isGranted) {
      // Acceder a los contactos
      List<Contact> contacts = await ContactsService.getContacts();
      setState(() {
        _contacts = contacts;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(
          "Lista de Contactos",
          style: TextStyle(
            color: Colors.white, // Cambia el color del texto aquí
          ),
        ),
      ),
      body: _contacts.isEmpty
          ? shimmerLoadingEffect()
          : Container(
              color: Colors.black87,
              child: ListView.builder(
                itemCount: _contacts.length,
                itemBuilder: (context, index) {
                  return _buildContactRow(_contacts[index]);
                },
              ),
            ),
    );
  }

  Widget shimmerLoadingEffect() {
    return Container(
      color: Colors.black87,
      child: ListView.builder(
        itemCount:
            5, // Cantidad de elementos ficticios para mostrar el efecto de carga
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[700]!,
            highlightColor: Colors.grey[600]!,
            child: Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 10,
                          color: Colors.grey[800],
                        ),
                        SizedBox(height: 5),
                        Container(
                          width: double.infinity,
                          height: 10,
                          color: Colors.grey[800],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: Colors.grey[800]),
                        ),
                      ),
                      Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContactRow(Contact contact) {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // Columna 1: Icono de usuario
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(Icons.person),
          ),
          SizedBox(width: 10),
          // Columna 2: Nombre y número del contacto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.displayName ?? '',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  contact.phones?.isNotEmpty == true
                      ? contact.phones?.first.value ?? ''
                      : '',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          // Columna 3: Botones
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding:
                    EdgeInsets.only(right: 10), // Espacio entre los botones
                child: ElevatedButton(
                  onPressed: () {
                    _handleCall(
                        context, contact.phones?.first.value ?? '', true);
                  },
                  child: Icon(Icons.call, color: Colors.white, size: 25),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _handleCall(context, contact.phones?.first.value ?? '');
                },
                child:
                    Icon(Icons.videocam_rounded, color: Colors.white, size: 25),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

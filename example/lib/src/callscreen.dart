import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

import 'widgets/action_button.dart';

class CallScreenWidget extends StatefulWidget {
  final SIPUAHelper? _helper;
  final Call? _call;
  CallScreenWidget(this._helper, this._call, {Key? key}) : super(key: key);
  @override
  _MyCallScreenWidget createState() => _MyCallScreenWidget();
}

class _MyCallScreenWidget extends State<CallScreenWidget>
    implements SipUaHelperListener {
  RTCVideoRenderer? _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer? _remoteRenderer = RTCVideoRenderer();
  double? _localVideoHeight;
  double? _localVideoWidth;
  EdgeInsetsGeometry? _localVideoMargin;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  bool _showNumPad = false;
  String _timeLabel = '00:00';
  late Timer _timer;
  bool _audioMuted = false;
  bool _videoMuted = false;
  bool _speakerOn = false;
  bool _hold = false;
  String? _holdOriginator;
  CallStateEnum _state = CallStateEnum.NONE;
  SIPUAHelper? get helper => widget._helper;

  bool isSecondCall = false;

  String callId1 = "";
  String callId2 = "";

  bool secondCallStartered = false;

  final SIPUAHelper helper2 = SIPUAHelper();

  AudioCache audioCache = AudioCache();
  AudioPlayer player = AudioPlayer();

  bool get voiceOnly =>
      (_localStream == null || _localStream!.getVideoTracks().isEmpty) &&
      (_remoteStream == null || _remoteStream!.getVideoTracks().isEmpty);

  String? get remoteIdentity => call!.remote_identity;

  String get direction => call!.direction;

  Call? get call => widget._call;

  late Call call2;

  String? get id => call!.id;

  bool isFirstCalling = true;

  late SharedPreferences _preferences;

  TextEditingController? _textController;

  late String _wsUriController;
  late String _passwordController;
  late String _authorizationUserController;

  @override
  initState() {
    super.initState();
    _initRenderers();
    _loadSettings();
    helper!.addSipUaHelperListener(this);
    helper2.addSipUaHelperListener(this);
    _startTimer();
    isFirstCalling = true;
    //_showIncomingCallNotification();
  }

  @override
  deactivate() {
    super.deactivate();
    helper!.removeSipUaHelperListener(this);
    _disposeRenderers();
  }

  void _loadSettings() async {
    _preferences = await SharedPreferences.getInstance();
    _sendAuthSecondHelper();

    _textController = TextEditingController(text: "");
    _textController!.text = "";

    setState(() {});
  }

  void _sendAuthSecondHelper() {
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

    settings.uri = 'sip:$_authorizationUserController@143.244.209.136';
    settings.authorizationUser = _authorizationUserController;
    settings.password = _passwordController;
    settings.userAgent = 'Dart SIP Client v1.0.0';
    settings.dtmfMode = DtmfMode.RFC2833;

    helper2.start(settings);
  }

  void saveCallHistory(String phoneNumber, bool isCallIn) async {
    if (!isFirstCalling) {
      return;
    } else {
      isFirstCalling = false;
    }

    if (isCallIn) {
      playSound();
    }

    final prefs = await SharedPreferences.getInstance();
    final extension = prefs.getString('extension');
    final callHistory = prefs.getStringList('call_history_$extension') ?? [];

    callHistory.add(
        '$phoneNumber,${isCallIn ? 'Llamada entrante' : 'Llamada saliente'},${DateTime.now()}');

    await prefs.setStringList('call_history_$extension', callHistory);
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      Duration duration = Duration(seconds: timer.tick);
      if (mounted) {
        setState(() {
          _timeLabel = [duration.inMinutes, duration.inSeconds]
              .map(
                (seg) => seg.remainder(60).toString().padLeft(2, '0'),
              )
              .join(':');
        });
      } else {
        _timer.cancel();
      }
    });
  }

  void _initRenderers() async {
    if (_localRenderer != null) {
      await _localRenderer!.initialize();
    }
    if (_remoteRenderer != null) {
      await _remoteRenderer!.initialize();
    }
  }

  void _disposeRenderers() {
    if (_localRenderer != null) {
      _localRenderer!.dispose();
      _localRenderer = null;
    }
    if (_remoteRenderer != null) {
      _remoteRenderer!.dispose();
      _remoteRenderer = null;
    }
  }

  void playSound() async {
    player = await audioCache.loop('sounds/call_sound.mp3');
  }

  void stopSound() {
    player.stop();
  }

  @override
  void callStateChanged(Call call, CallState callState) {
    if (callId1 == "") {
      callId1 = call.id!;
    }

    if (callId1 != call.id && (callId2 == "" || callId2 == call.id)) {
      if (callState.state == CallStateEnum.CALL_INITIATION &&
          secondCallStartered) {
        secondCallStartered = false;
        callId2 = call.id!;
        isSecondCall = true;
        call2 = call;
      }
      return;
    }

    if (callState.state == CallStateEnum.HOLD ||
        callState.state == CallStateEnum.UNHOLD) {
      _hold = callState.state == CallStateEnum.HOLD;
      _holdOriginator = callState.originator;
      setState(() {});
      return;
    }

    if (callState.state == CallStateEnum.MUTED) {
      if (callState.audio!) _audioMuted = true;
      if (callState.video!) _videoMuted = true;
      setState(() {});
      return;
    }

    if (callState.state == CallStateEnum.UNMUTED) {
      if (callState.audio!) _audioMuted = false;
      if (callState.video!) _videoMuted = false;
      setState(() {});
      return;
    }

    if (callState.state != CallStateEnum.STREAM && callId1 == call.id) {
      _state = callState.state;
    }
    switch (callState.state) {
      case CallStateEnum.STREAM:
        _handelStreams(callState);
        break;
      case CallStateEnum.ENDED:
      case CallStateEnum.FAILED:
        if (!isSecondCall) {
          _backToDialPad();
        }
        break;
      case CallStateEnum.UNMUTED:
      case CallStateEnum.MUTED:
      case CallStateEnum.CONNECTING:
      case CallStateEnum.PROGRESS:
      case CallStateEnum.ACCEPTED:
      case CallStateEnum.CONFIRMED:
      case CallStateEnum.HOLD:
      case CallStateEnum.UNHOLD:
      case CallStateEnum.NONE:
      case CallStateEnum.CALL_INITIATION:
        break;
      case CallStateEnum.REFER:
        break;
    }
  }

  @override
  void transportStateChanged(TransportState state) {}

  @override
  void registrationStateChanged(RegistrationState state) {}

  void _cleanUp() {
    if (_localStream == null) return;
    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    _localStream!.dispose();
    _localStream = null;
  }

  void _backToDialPad() {
    _timer.cancel();
    Timer(Duration(seconds: 2), () {
      stopSound();
      Navigator.of(context).pop();
    });
    _cleanUp();
  }

  void _handelStreams(CallState event) async {
    MediaStream? stream = event.stream;
    if (event.originator == 'local') {
      if (_localRenderer != null) {
        await _localRenderer!.initialize();
        _localRenderer!.srcObject = stream;
      }
      if (!kIsWeb && !WebRTC.platformIsDesktop) {
        event.stream?.getAudioTracks().first.enableSpeakerphone(false);
      }
      _localStream = stream;
    }
    if (event.originator == 'remote') {
      if (_remoteRenderer != null) {
        _remoteRenderer!.srcObject = stream;
      }
      _remoteStream = stream;
    }

    setState(() {
      _resizeLocalVideo();
    });
  }

  void _resizeLocalVideo() {
    _localVideoMargin = _remoteStream != null
        ? EdgeInsets.only(top: 15, right: 15)
        : EdgeInsets.all(0);
    _localVideoWidth = _remoteStream != null
        ? MediaQuery.of(context).size.width / 4
        : MediaQuery.of(context).size.width;
    _localVideoHeight = _remoteStream != null
        ? MediaQuery.of(context).size.height / 4
        : MediaQuery.of(context).size.height;
  }

  void _handleHangup() {
    call!.hangup({'status_code': 603});
    _timer.cancel();
    _state = CallStateEnum.ENDED;
    setState(() {});
  }

  void _handleAccept() async {
    stopSound();
    bool remoteHasVideo = call!.remote_has_video;
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': remoteHasVideo
    };
    MediaStream mediaStream;

    if (kIsWeb && remoteHasVideo) {
      mediaStream =
          await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
      mediaConstraints['video'] = false;
      MediaStream userStream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      mediaStream.addTrack(userStream.getAudioTracks()[0], addToNative: true);
    } else {
      mediaConstraints['video'] = remoteHasVideo;
      mediaStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    }

    call!.answer(helper!.buildCallOptions(!remoteHasVideo),
        mediaStream: mediaStream);
  }

  void _switchCamera() {
    if (_localStream != null) {
      Helper.switchCamera(_localStream!.getVideoTracks()[0]);
    }
  }

  void _muteAudio() {
    if (_audioMuted) {
      call!.unmute(true, false);
    } else {
      call!.mute(true, false);
    }
  }

  void _muteVideo() {
    if (_videoMuted) {
      call!.unmute(false, true);
    } else {
      call!.mute(false, true);
    }
  }

  void _handleHold() {
    if (_hold) {
      call!.unhold();
    } else {
      call!.hold();
    }
  }

  late String _transferTarget;
  void _handleTransfer() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter target to transfer.'),
          content: TextField(
            onChanged: (String text) {
              setState(() {
                _transferTarget = text;
              });
            },
            decoration: InputDecoration(
              hintText: 'URI or Username',
            ),
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Ok'),
              onPressed: () {
                call!.refer(_transferTarget);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _handleDtmf(String tone) {
    setState(() {
      _textController!.text += tone;
    });
    print('Dtmf tone => $tone');
    call!.sendDTMF(tone);
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

  Future<Widget?> _handleCall(BuildContext context,
      [bool voiceOnly = false]) async {
    if (isSecondCall) {
      secondCallStartered = false;
      call2.hangup({'status_code': 603});
      isSecondCall = false;
      callId2 = "";
      if (call?.state.toString() == "CallStateEnum.ENDED") {
        _backToDialPad();
      }
      return null;
    } else {
      secondCallStartered = true;
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
              title: Text('Target is empty.'),
              content: Text('Please enter a SIP URI or username!'),
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

    helper2.call(
      destUri,
      voiceonly: voiceOnly,
      mediaStream: mediaStream,
    );
    return null;
  }

  void _handleKeyPad() {
    setState(() {
      _showNumPad = !_showNumPad;
    });
  }

  void _toggleSpeaker() {
    if (_localStream != null) {
      _speakerOn = !_speakerOn;
      if (!kIsWeb) {
        _localStream!.getAudioTracks()[0].enableSpeakerphone(_speakerOn);
      }
    }
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
            padding: const EdgeInsets.all(3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row
                  .map(
                    (label) => ActionButton(
                      title: label.keys.first,
                      subTitle: label.values.first,
                      onPressed: () => _handleDtmf(label.keys.first),
                      number: true,
                    ),
                  )
                  .toList(),
            ),
          ),
        )
        .toList();
  }

  Widget _buildActionButtons() {
    var hangupBtn = ActionButton(
      title: "hangup",
      onPressed: () => _handleHangup(),
      icon: Icons.call_end,
      fillColor: Colors.red,
    );

    var hangupBtnInactive = ActionButton(
      title: "hangup",
      onPressed: () {},
      icon: Icons.call_end,
      fillColor: Colors.grey,
    );

    var basicActions = <Widget>[];
    var advanceActions = <Widget>[];

    switch (_state) {
      case CallStateEnum.NONE:
      case CallStateEnum.CONNECTING:
        if (direction == 'INCOMING') {
          basicActions.add(ActionButton(
            title: "Accept",
            fillColor: Colors.green,
            icon: Icons.phone,
            onPressed: () => _handleAccept(),
          ));
          basicActions.add(hangupBtn);
        } else {
          basicActions.add(hangupBtn);
        }
        saveCallHistory(remoteIdentity!, direction == 'INCOMING');
        break;
      case CallStateEnum.ACCEPTED:
      case CallStateEnum.CONFIRMED:
        {
          advanceActions.add(
            ActionButton(
              title: _audioMuted ? 'unmute' : 'mute',
              icon: _audioMuted ? Icons.mic_off : Icons.mic,
              checked: _audioMuted,
              onPressed: () => _muteAudio(),
            ),
          );

          advanceActions.add(
            ActionButton(
              title: _speakerOn ? 'speaker off' : 'speaker on',
              icon: _speakerOn ? Icons.volume_off : Icons.volume_up,
              checked: _speakerOn,
              onPressed: () => _toggleSpeaker(),
            ),
          );

          if (voiceOnly) {
            advanceActions.add(
              ActionButton(
                title: "keypad",
                icon: Icons.dialpad,
                onPressed: () => _handleKeyPad(),
              ),
            );
          } else {
            advanceActions.add(
              ActionButton(
                title: "switch",
                icon: Icons.switch_video,
                onPressed: () => _switchCamera(),
              ),
            );

            advanceActions.add(
              ActionButton(
                title: _videoMuted ? "camera on" : 'camera off',
                icon: _videoMuted ? Icons.videocam : Icons.videocam_off,
                checked: _videoMuted,
                onPressed: () => _muteVideo(),
              ),
            );
          }

          basicActions.add(
            ActionButton(
              fillColor: isSecondCall
                  ? Color.fromARGB(255, 194, 132, 128)
                  : Colors.red,
              title: _hold ? 'unhold' : 'hold',
              icon: _hold ? Icons.play_arrow : Icons.pause,
              checked: _hold,
              onPressed: isSecondCall ? null : () => _handleHold(),
            ),
          );

          basicActions.add(hangupBtn);

          if (_showNumPad) {
            basicActions.add(
              ActionButton(
                fillColor: isSecondCall ? Colors.black : null,
                title: "back",
                icon: Icons.keyboard_arrow_down,
                onPressed: isSecondCall ? null : () => _handleKeyPad(),
              ),
            );
          } else {
            basicActions.add(
              ActionButton(
                title: "transfer",
                icon: Icons.phone_forwarded,
                onPressed: () => _handleTransfer(),
              ),
            );
          }
        }
        break;
      case CallStateEnum.FAILED:
        break;
      case CallStateEnum.ENDED:
        basicActions.add(hangupBtnInactive);
        break;
      case CallStateEnum.PROGRESS:
        basicActions.add(hangupBtn);
        break;
      default:
        print('Other state => $_state');
        break;
    }

    var actionWidgets = <Widget>[];

    if (_showNumPad) {
      //actionWidgets.addAll(_buildNumPad());
      actionWidgets.addAll([
        isSecondCall
            ? Container(
                margin: EdgeInsets.only(bottom: 200),
                child: Column(
                  children: <Widget>[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Padding(
                          padding: EdgeInsets.only(top: 30),
                          child: Text(
                            (call2.state.toString() == "CallStateEnum.CONFIRMED"
                                ? 'SECOND VOICE CALL'
                                : 'CONECTING SECOND CALL...'),
                            style: TextStyle(fontSize: 24, color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          '${_textController?.text}',
                          style: TextStyle(fontSize: 18, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Container(
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
                      ),
                    ),
                  ],
                ),
              ),
        isSecondCall
            ? Container()
            : Container(
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
                  icon: isSecondCall ? Icons.call_end : Icons.dialer_sip,
                  fillColor: isSecondCall
                      ? (_hold
                          ? Colors.red
                          : Color.fromARGB(255, 222, 137, 131))
                      : (_hold
                          ? Colors.green
                          : Color.fromARGB(255, 151, 198, 153)),
                  onPressed: !_hold ? null : () => _handleCall(context, true),
                ),
                if (!isSecondCall)
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
      ]);
    } else {
      if (advanceActions.isNotEmpty) {
        actionWidgets.add(
          Padding(
            padding: const EdgeInsets.all(0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: advanceActions,
            ),
          ),
        );
      }
    }

    actionWidgets.add(
      Padding(
        padding: const EdgeInsets.all(0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: basicActions,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.end,
      children: actionWidgets,
    );
  }

  Widget _buildContent() {
    var stackWidgets = <Widget>[];

    if (!voiceOnly && _remoteStream != null) {
      stackWidgets.add(Center(
        child: RTCVideoView(_remoteRenderer!),
      ));
    }

    if (!voiceOnly && _localStream != null) {
      stackWidgets.add(Container(
        child: AnimatedContainer(
          child: RTCVideoView(_localRenderer!),
          height: _localVideoHeight,
          width: _localVideoWidth,
          alignment: Alignment.topRight,
          duration: Duration(milliseconds: 300),
          margin: _localVideoMargin,
        ),
        alignment: Alignment.topRight,
      ));
    }

    stackWidgets.addAll(
      [
        Positioned(
          top: voiceOnly ? 48 : 6,
          left: 0,
          right: 0,
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: Text(
                        (voiceOnly ? 'VOICE CALL' : 'VIDEO CALL') +
                            (_hold &&
                                    !(call?.state.toString() ==
                                        "CallStateEnum.ENDED")
                                ? ' PAUSED BY ${_holdOriginator!.toUpperCase()}'
                                : (call?.state.toString() ==
                                        "CallStateEnum.ENDED")
                                    ? ' ENDED'
                                    : ''),
                        style: TextStyle(fontSize: 24, color: Colors.black),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      '$remoteIdentity',
                      style: TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ),
                ),
                Center(
                    child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(_timeLabel,
                            style:
                                TextStyle(fontSize: 14, color: Colors.black))))
              ],
            ),
          ),
        ),
      ],
    );

    return Container(
      color: Colors.white, // Establece el color de fondo negro
      child: Stack(
        children: stackWidgets,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: _buildContent(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
        child: Container(
          child: _buildActionButtons(),
        ),
      ),
    );
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  void onNewNotify(Notify ntf) {}
}

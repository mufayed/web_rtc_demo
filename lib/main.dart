import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_rtc_demo/signaling.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebRTC Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Signaling signaling = Signaling();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String? roomId;
  TextEditingController textEditingController = TextEditingController(text: '');

  @override
  void initState() {
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    signaling.getRooms();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "WebRTC",
          style: TextStyle(fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: RTCVideoView(_localRenderer, mirror: true)),
                  Expanded(child: RTCVideoView(_remoteRenderer)),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showOptions();
        },
        child: const Icon(Icons.settings),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  _showOptions() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Create room'),
                onTap: () async {
                  Navigator.of(context).pop();
                  signaling.openCamera(_localRenderer, _remoteRenderer);
                  roomId = await signaling.createRoom();
                  textEditingController.text = roomId!;
                  setState(() {});
                },
              ),
              ListTile(
                leading: const Icon(Icons.open_in_browser_outlined),
                title: const Text('Join room'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('End the connection'),
                onTap: () {
                  roomId = null;
                  signaling.endConnection(_localRenderer);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  _showDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Join room"),
            content: SizedBox(
              height: 150,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: textEditingController,
                    decoration: const InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          // width: 0.0 produces a thin "hairline" border
                          borderSide:
                              BorderSide(color: Colors.indigo, width: 0.0),
                        ),
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(color: Colors.indigo),
                        hintText: 'Room ID'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextButton(
                    onPressed: () {
                      if (textEditingController.text.isNotEmpty) {
                        Navigator.of(context).pop();
                        signaling.openCamera(_localRenderer, _remoteRenderer);
                        signaling.joinRoom(
                          textEditingController.text,
                        );
                      }
                    },
                    child: const Text(
                      'Join',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.indigo)),
                  )
                ],
              ),
            ),
          );
        });
  }
}
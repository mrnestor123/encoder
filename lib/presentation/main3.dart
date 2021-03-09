// For performing some operations asynchronously
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

// For using PlatformException
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BluetoothApp(),
    );
  }
}

class BluetoothApp extends StatefulWidget {
  @override
  _BluetoothAppState createState() => _BluetoothAppState();
}

class _BluetoothAppState extends State<BluetoothApp> {
  // Initializing a global key, as it would help us in showing a SnackBar later
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  // Get the instance of the Bluetooth
  // Track the Bluetooth connection with the remote device

  int _deviceState;

  bool started = false;

  bool isDisconnecting = false;

  // Define some variables, which will be required later
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice _device;
  bool _connected = false;
  bool _isButtonUnavailable = false;

  List<String> states = ["Velocidad", "Fuerza", "Potencia"];
  int currentstateposition = 0;
  String state = "Velocidad";

  FlutterBlue flutterBlue;

  @override
  void initState() {
    super.initState();
    // Get current state
    flutterBlue = FlutterBlue.instance;
    _deviceState = 0; 
    enableBluetooth();
    getPairedDevices();
    _connect();
  }

  @override
  void dispose() {
    // Avoid memory leak and disconnect
    // if (isConnected) {
    //   isDisconnecting = true;
    //   connection.dispose();
    //   connection = null;
    // }

    super.dispose();
  }

  // Request Bluetooth permission from the user
  Future<void> enableBluetooth() async {
    // Retrieving the current Bluetooth state
    if (await FlutterBlue.instance.isOn) {
    } else {
      show('Enable bluetooth to continue');
    }
  }

  // For retrieving and storing the paired devices
  // in a list.
  Future<void> getPairedDevices() async {
    // Start scanning
    flutterBlue.startScan(timeout: Duration(seconds: 4));
    // Listen to scan results
    var subscription = flutterBlue.scanResults.listen((results) {
      // do something with scan results
      for (ScanResult r in results) {
        print('${r.device}');
        print('${r.device.name} found! rssi: ${r.rssi}');
      }
    });
    print('scanning');
    // Stop scanning
    // List<BluetoothDevice> devices = [];

    // // To get the list of paired devices
    // try {
    //   devices = await _bluetooth.getBondedDevices();
    // } on PlatformException {
    //   print("Error");
    // }
    // // It is an error to call [setState] unless [mounted] is true.
    // if (!mounted) {
    //   return;
    // }
    // // Store the [devices] list in the [_devicesList] for accessing
    // // the list outside this class
    // setState(() {
    //   _devicesList = devices;
    // });
  }

  // Now, its time to build the UI
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        bottomNavigationBar:
            BottomNavigationBar(items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            title: Text('Inicio'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart),
            title: Text('Resultados'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            title: Text('Perfil'),
          ),
        ]),
        appBar: AppBar(
          title: Center(child: Text("Barras' gym")),
          backgroundColor: Colors.black54,
        ),
        body: Container(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        SizedBox(height: 50),
                        started
                            ? GestureDetector(
                                onDoubleTap: () => setState(() {
                                  if (currentstateposition < states.length) {
                                    state = states[currentstateposition++];
                                  } else {
                                    currentstateposition = 0;
                                    state = states[currentstateposition++];
                                  }
                                }),
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  child: Column(children: <Widget>[
                                    Text(state, style: TextStyle(fontSize: 25)),
                                    SizedBox(height: 10),
                                    Container(
                                        padding: EdgeInsets.all(32),
                                        decoration: BoxDecoration(
                                          color: Colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '65',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 125),
                                        )),
                                    SizedBox(height: 80),
                                    RaisedButton(
                                        color: Colors.red,
                                        onPressed: () =>
                                            setState(() => started = false),
                                        child: Text('STOP'))
                                  ]),
                                ),
                              )
                            : Container(
                                color: Colors.white,
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Text("Ejercicio"),
                                            Text("Squat")
                                          ]),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Text("Personas"),
                                            Text("Hulk")
                                          ]),
                                      RaisedButton(
                                          onPressed: () =>
                                              setState(() => started = true),
                                          color: Colors.white,
                                          child: Text('Start'))
                                    ]))
                      ],
                    ),
                    Container(
                      color: Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Method to connect to bluetooth
  void _connect() async {

    print('connecting');

    for (var device in await flutterBlue.connectedDevices) {
      print('device: ' + device.name);
    }


    // if (_device == null) {
    //   show('No device selected');
    // } else {
    //   if (!isConnected) {
    //     try {
    //       await BluetoothConnection.toAddress(_device.address)
    //           .then((_connection) {
    //         print('Connected to the device');
    //         connection = _connection;
    //         setState(() {
    //           _connected = true;
    //         });

    //         int counter = 0;
    //         connection.input.listen((Uint8List data) {
    //           connection.output.add(data); // Sending data
    //           counter++;
    //           if (counter % 12 == 0) {
    //             var string = utf8.decode(data);
    //             print(string);
    //             print('count ' + counter.toString());
    //           }

    //           //String s = new String.fromCharCodes(data);
    //           //print(s);
    //         }).onDone(() {
    //           if (isDisconnecting) {
    //             print('Disconnecting locally!');
    //           } else {
    //             print('Disconnected remotely!');
    //           }
    //           if (this.mounted) {
    //             setState(() {});
    //           }
    //         });
    //       });

    //       show('Device connected');
    //     } on Exception {
    //       show('Cant connect');
    //     }
  }

  // Method to disconnect bluetooth
  // void _disconnect() async {
  //   setState(() {
  //     _isButtonUnavailable = true;
  //     _deviceState = 0;
  //   });

  //   await connection.close();
  //   show('Device disconnected');
  //   if (!connection.isConnected) {
  //     setState(() {
  //       _connected = false;
  //       _isButtonUnavailable = false;
  //     });
  //   }
  // }

  // Method to show a Snackbar,
  // taking message as the text
  Future show(
    String message, {
    Duration duration: const Duration(seconds: 3),
  }) async {
    await new Future.delayed(new Duration(milliseconds: 100));
    _scaffoldKey.currentState.showSnackBar(
      new SnackBar(
        content: new Text(
          message,
        ),
        duration: duration,
      ),
    );
  }
}

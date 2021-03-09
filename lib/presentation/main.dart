// For performing some operations asynchronously
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

// For using PlatformException
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth/presentation/radial_progress.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme:
            ThemeData(primarySwatch: Colors.blue, brightness: Brightness.light),
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(brightness: Brightness.dark),
        title: 'Flutter Demo',
        initialRoute: '/main',
        routes: {
          '/main': (context) => BluetoothApp(),
          '/stats': (context) => BluetoothApp(),
        });
  }
}

class BluetoothApp extends StatefulWidget {
  @override
  _BluetoothAppState createState() => _BluetoothAppState();
}

class _BluetoothAppState extends State<BluetoothApp> {
  // Initializing the Bluetooth connection state to be unknown
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  // Initializing a global key, as it would help us in showing a SnackBar later
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  // Get the instance of the Bluetooth
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  // Track the Bluetooth connection with the remote device
  BluetoothConnection connection;

  int _deviceState;

  String velocidad = "";

  bool started = true;

  bool isDisconnecting = false;

  Map<String, Color> colors = {
    'onBorderColor': Colors.green,
    'offBorderColor': Colors.red,
    'neutralBorderColor': Colors.transparent,
    'onTextColor': Colors.green[700],
    'offTextColor': Colors.red[700],
    'neutralTextColor': Colors.blue,
  };

  // To track whether the device is still connected to Bluetooth
  bool get isConnected => connection != null && connection.isConnected;

  // Define some variables, which will be required later
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice _device;
  bool _connected = false;
  bool _isButtonUnavailable = false;

  List<String> states = ["Speed", "Acceleration", "Power"];
  int stateindex = 0;
  List<String> currentvalues = ["0.0", "0.0", "0.0"];
  List<double> max = [0, 0, 0];
  double maxaccel, maxpot = 0;
  // indice cambiará para mostrar velocidad, aceleración y potencia.

  List<double> totalvelocities = [];
  List<double> totalacceleration = [];
  List<double> totalpotencia = [];

  String state = "Velocidad";

  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    _deviceState = 0; // neutral

    // If the bluetooth of the device is not enabled,
    // then request permission to turn on bluetooth
    // as the app starts up
    enableBluetooth();

    // Listen for further state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
        if (_bluetoothState == BluetoothState.STATE_OFF) {
          _isButtonUnavailable = true;
        }
        getPairedDevices();
      });
    });
  }

  @override
  void dispose() {
    // Avoid memory leak and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }

    super.dispose();
  }

  // Request Bluetooth permission from the user
  Future<void> enableBluetooth() async {
    // Retrieving the current Bluetooth state
    _bluetoothState = await FlutterBluetoothSerial.instance.state;

    // If the bluetooth is off, then turn it on first
    // and then retrieve the devices that are paired.
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
      return true;
    } else {
      await getPairedDevices();
    }
    return false;
  }

  // For retrieving and storing the paired devices
  // in a list.
  Future<void> getPairedDevices() async {
    List<BluetoothDevice> devices = [];

    // To get the list of paired devices
    try {
      devices = await _bluetooth.getBondedDevices();
    } on PlatformException {
      print("Error");
    }

    // It is an error to call [setState] unless [mounted] is true.
    if (!mounted) {
      return;
    }

    // Store the [devices] list in the [_devicesList] for accessing
    // the list outside this class
    setState(() {
      _devicesList = devices;
    });
  }

  // Now, its time to build the UI
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          key: _scaffoldKey,
          bottomNavigationBar: BottomNavBar(),
          backgroundColor: Colors.black,
          body: Stack(
             overflow: Overflow.visible,
            children: [
            !_connected
                ? Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                        Text('Encoder app',
                            style:
                                Theme.of(context).primaryTextTheme.headline3),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.1),
                        DropdownButton(
                          items: _getDeviceItems(),
                          onChanged: (value) => setState(() => _device = value),
                          value: _devicesList.isNotEmpty ? _device : null,
                        ),
                        RawMaterialButton(
                          onPressed: () {
                            setState(() => _connected = true);
                          },
                          elevation: 2.0,
                          fillColor: Colors.lightBlue,
                          child: Center(
                            child: Padding(
                                padding: const EdgeInsets.all(64.0),
                                child: Text('Connect',
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .headline6)),
                          ),
                          shape: CircleBorder(),
                        ),
                      ]))
                : ListView(children: [
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(40),
                              topRight: Radius.circular(40))),
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.only(top:50),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: null,
                                      color: Colors.amber[800])
                                ]),
                            GestureDetector(
                              onDoubleTap: () => setState(() {
                                if (stateindex < max.length - 1) {
                                  state = states[++stateindex];
                                } else {
                                  stateindex = 0;
                                  state = states[stateindex];
                                }
                              }),
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                child: Column(children: <Widget>[
                                  RadialProgress(
                                      text: state, goalCompleted: 0.7),
                                  //RadialProgress(currentvalues: currentvalues, stateindex: stateindex, max: max),
                                  SizedBox(height: 80),
                                  //RaisedButton(
                                  //  color: Colors.red,
                                  //onPressed: () =>
                                  //  setState(() => started = false),
                                  //    child: Text('STOP'))
                                ]),
                              ),
                            ),
                            SizedBox(height: 500)
                          ]),
                    ),
                  ]),
            !_connected
                ? Positioned(
                    top:0,
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.20,
                      child: Center(
                          child: Text('Encoder app',
                              style: Theme.of(context).textTheme.headline4)),
                    ))
                : Container(),
          ])),
    );
  }

  // Create the List of devices to be shown in Dropdown Menu
  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devicesList.isEmpty) {
      items.add(DropdownMenuItem(
        child: Text('NONE'),
      ));
    } else {
      _devicesList.forEach((device) {
        items.add(DropdownMenuItem(
          child: Text(device.name),
          value: device,
        ));
      });
    }
    return items;
  }

  // Method to connect to bluetooth
  void _connect() async {
    setState(() {
      _isButtonUnavailable = true;
    });
    if (_device == null) {
      show('No device selected');
    } else {
      if (!isConnected) {
        try {
          await BluetoothConnection.toAddress(_device.address)
              .then((_connection) {
            print('Connected to the device');
            connection = _connection;
            setState(() {
              _connected = true;
            });

            int counter = 0;
            // Uint8List auxiliar = new Uint8List(12);
            List<int> aux = new List<int>();
            var auxstring = '';
            connection.input.listen((Uint8List data) {
              var string = utf8.decode(data);
              if (string.startsWith("<")) {
                setState(() {
                  currentvalues = auxstring.substring(1).split(',');
                  print('index :' + stateindex.toString());
                  print(currentvalues);
                  if (double.parse(currentvalues[stateindex]) >
                      max[stateindex]) {
                    max[stateindex] = double.parse(currentvalues[0]);
                  }
                  totalvelocities.add(double.parse(currentvalues[0]));
                  totalacceleration.add(double.parse(currentvalues[1]));
                  // totalpotencia.add(currentvalues[2]);
                });
                auxstring = '';
                auxstring += string;
              } else {
                auxstring += string;
              }

              //connection.output.add(data); // Sending data

              //setState(()=> velocidad = string);

              //String s = new String.fromCharCodes(data);
              //print(s);
            }).onDone(() {
              if (isDisconnecting) {
                print('Disconnecting locally!');
              } else {
                print('Disconnected remotely!');
              }
              if (this.mounted) {
                setState(() {});
              }
            });
          });

          show('Device connected');
        } on Exception {
          show('Cant connect');
        }

        setState(() => _isButtonUnavailable = false);
      }
    }
  }

  // Method to disconnect bluetooth
  void _disconnect() async {
    setState(() {
      _isButtonUnavailable = true;
      _deviceState = 0;
    });

    await connection.close();
    show('Device disconnected');
    if (!connection.isConnected) {
      setState(() {
        _connected = false;
        _isButtonUnavailable = false;
      });
    }
  }

  // Method to send message,
  // for turning the Bluetooth device on
  void _sendOnMessageToBluetooth() async {
    connection.output.add(utf8.encode("1" + "\r\n"));
    await connection.output.allSent;
    show('Device Turned On');
    setState(() {
      _deviceState = 1; // device on
    });
  }

  // Method to send message,
  // for turning the Bluetooth device off
  void _sendOffMessageToBluetooth() async {
    connection.output.add(utf8.encode("0" + "\r\n"));
    await connection.output.allSent;
    show('Device Turned Off');
    setState(() {
      _deviceState = -1; // device off
    });
  }

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

class RadialProgresswhite extends StatelessWidget {
  const RadialProgresswhite({
    Key key,
    @required this.currentvalues,
    @required this.stateindex,
    @required this.max,
  }) : super(key: key);

  final List<String> currentvalues;
  final int stateindex;
  final List<double> max;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(32),
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              currentvalues[stateindex],
              style: TextStyle(color: Colors.white, fontSize: 60),
            ),
            Text(max[stateindex].toString())
          ],
        ));
  }
}

class BottomNavBar extends StatefulWidget {
  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

List<String> routes = ['/main', '/stats', '/profile'];

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.white38,
        items: const <BottomNavigationBarItem>[
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
        ]);
  }
}

/* Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width*0.8,
                    height: MediaQuery.of(context).size.height*0.6,
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.0),color:Colors.black87,boxShadow: [BoxShadow(color:Colors.grey,blurRadius:8.0,spreadRadius:3.0, offset:Offset(0,3))]),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text('Start training',style: Theme.of(context).primaryTextTheme.headline4),
                          SizedBox(height: MediaQuery.of(context).size.height*0.05),
                          Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                Text("Exercise",style: Theme.of(context).primaryTextTheme.headline6),
                                Text("Squat")
                              ]),
                          SizedBox(height: MediaQuery.of(context).size.height*0.02),
                          Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                Text("People",style: Theme.of(context).primaryTextTheme.headline6),
                                Text("Hulk")
                              ]),
                          SizedBox(height: MediaQuery.of(context).size.height*0.04),
                          RaisedButton(
                              onPressed: () =>
                                  setState(() => started = true),
                              color: Colors.white,
                              child: Text('Start'))
                        ]),
                  ),
                ),*/

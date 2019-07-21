import 'dart:math';

import 'package:flutter/material.dart';
import 'package:volume/volume.dart';
import 'package:sensors/sensors.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jerk Volume',
      theme: ThemeData.dark(),
      home: VolumePage(title: 'Jerk Volume'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class VolumePage extends StatefulWidget {
  VolumePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  VolumePageState createState() => VolumePageState();
}

class VolumePageState extends State<VolumePage> {
  int maxVol, currentVol;
  double addingVolume = 0;
  int previous = -1;

  AudioManager audioManager;

  @override
  void initState() {
    super.initState();
    print('Before init');
    audioManager = AudioManager.STREAM_MUSIC;
    initPlatformState();
    updateVolumes();

    accelerometerEvents.listen((AccelerometerEvent event) {
      if (currentVol == null) return;

      var y = event.y.abs();
      bool down = y < 25;

      double volumeAcceleration;
      if (down) {
        volumeAcceleration = -0.1;
      } else {
        volumeAcceleration = (y - 25) / 75;
      }

//      double volumeAcceleration = (down ? -1 : 1) * sqrt(y.abs());
      addingVolume += volumeAcceleration;
      if (addingVolume < 0) {
        addingVolume = 0;
      } else if (addingVolume > maxVol) {
        addingVolume = maxVol.toDouble();
      }

      currentVol = max(min(addingVolume.round(), maxVol), 0);

//      print(currentVol);
//      print('$currentVol   [$volumeAcceleration]');

      if (previous != currentVol) {
        previous = currentVol;
        setVol(currentVol);
        updateVolumes();
      }
    });
  }

  Future<void> initPlatformState() async {
    await Volume.controlVolume(AudioManager.STREAM_MUSIC);
  }

  updateVolumes() async {
    // get Max Volume
    maxVol = await Volume.getMaxVol;
    // get Current Volume
    currentVol = await Volume.getVol;
  }

  setVol(int i) async {
    await Volume.setVol(i);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: size.width - 60,
              child: Text(
                'Jerk your phone to increase the volume. Don\'t stop or else it will go back down!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.display1,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('Pressed!');
          setVol(Random.secure().nextInt(maxVol));
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

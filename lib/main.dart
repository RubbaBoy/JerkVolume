import 'dart:math';

import 'package:flutter/material.dart';
import 'package:volume/volume.dart';
import 'package:sensors/sensors.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jerk Volume',
      theme: ThemeData.dark(),
      home: VolumePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class VolumePage extends StatefulWidget {
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

    Future(() {
      accelerometerEvents.listen((AccelerometerEvent event) {
        if (currentVol == null) return;

        var y = maxOfAll([event.x.abs(), event.y.abs(), event.z.abs()]);
        bool down = y < 25;

        double volumeAcceleration;
        if (down) {
          volumeAcceleration = -0.1;
        } else {
          volumeAcceleration = (y - 25) / 75;
        }

        addingVolume += volumeAcceleration;
        if (addingVolume < 0) {
          addingVolume = 0;
        } else if (addingVolume > maxVol) {
          addingVolume = maxVol.toDouble();
        }

        currentVol = max(min(addingVolume.round(), maxVol), 0);

        if (previous != currentVol) {
          previous = currentVol;
          setVol(currentVol);
          updateVolumes();
        }
      });
    });
  }

  double maxOfAll(List<double> nums) {
    double result = -1;
    nums.forEach((num) => result = max(num, result));
    return result;
  }

  Future<void> initPlatformState() async {
    await Volume.controlVolume(AudioManager.STREAM_MUSIC);
  }

  updateVolumes() async {
    maxVol = await Volume.getMaxVol;
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
        title: Text('Jerk Volume'),
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
    );
  }
}

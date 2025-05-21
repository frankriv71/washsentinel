import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_core/firebase_core.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String sensorStatus = "Unknown";
  List<String> alertHistory = [];
  Color statusColor = Colors.grey;
  late AnimationController _animationController;
  late AudioPlayer _audioPlayer;
  bool _isLoading = true;

  final DatabaseReference _alertsRef =
  FirebaseDatabase.instance.ref("alerts");

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _audioPlayer = AudioPlayer();
    _initAudioPlayer();

    _startFirebaseListener();
  }

  Future<void> _initAudioPlayer() async {
    try {
      await _audioPlayer.setAsset('assets/alarm.mp3');
    } catch (e) {
      print("Error loading audio asset: $e");
    }
  }

  void _startFirebaseListener() {
    _alertsRef.onChildAdded.listen((event) async {
      final alert = event.snapshot.value as Map<dynamic, dynamic>?;
      if (alert == null) return;

      String newStatus = alert['status'] ?? "Unknown";

      if (mounted) {
        if (newStatus == "ALERT" && sensorStatus != "ALERT") {
          if (_audioPlayer.playing) {
            await _audioPlayer.stop();
          }
          await _audioPlayer.seek(Duration.zero);
          await _audioPlayer.play();
          alertHistory.add(
              "ALERT detected at ${DateTime.now().toLocal().toString().substring(0, 19)}");
        }

        setState(() {
          sensorStatus = newStatus;
          _isLoading = false;
          statusColor = (sensorStatus == "ALERT")
              ? Theme.of(context).colorScheme.error
              : (sensorStatus == "OK")
              ? Colors.green
              : Colors.grey;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("WashSentinel"),
        elevation: 4.0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_bluetooth),
            onPressed: () {
              Navigator.pushNamed(context, '/setup');
            },
          )
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Connecting to Firebase..."),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(context),
            SizedBox(height: 24),
            Text(
              "Alert History",
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            _buildAlertHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    IconData statusIconData;
    switch (sensorStatus) {
      case "ALERT":
        statusIconData = Icons.warning_amber_rounded;
        break;
      case "OK":
        statusIconData = Icons.check_circle_outline_rounded;
        break;
      default:
        statusIconData = Icons.help_outline_rounded;
    }

    return Card(
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 24.0, horizontal: 16.0),
        child: Column(
          children: [
            Text(
              "Sensor Status",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            AnimatedBuilder(
              animation: _animationController,
              builder: (_, child) => Opacity(
                opacity: (sensorStatus == "ALERT")
                    ? _animationController.value.clamp(0.4, 1.0)
                    : 1.0,
                child: child,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    statusIconData,
                    color: statusColor,
                    size: 36,
                  ),
                  SizedBox(width: 16),
                  Text(
                    sensorStatus,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertHistoryList() {
    if (alertHistory.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off,
                  size: 48, color: Colors.grey[400]),
              SizedBox(height: 8),
              Text(
                "No alerts recorded yet.",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: ListView.separated(
          itemCount: alertHistory.length,
          reverse: true,
          itemBuilder: (context, index) {
            return ListTile(
              leading: Icon(
                Icons.notifications_active_outlined,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: Text(
                alertHistory[index],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              dense: true,
              contentPadding:
              EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            );
          },
          separatorBuilder: (context, index) => Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
        ),
      ),
    );
  }
}

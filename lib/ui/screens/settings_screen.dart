import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../providers/song_provider.dart';
import 'folder_management_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  static Route<void> route() {
    return MaterialPageRoute(builder: (context) => const SettingsScreen());
  }

  @override
  Widget build(BuildContext context) {
    final songProvider = Provider.of<SongProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Library",
              style: TextStyle(
                color: Colors.deepPurpleAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!songProvider.hasPermission)
            ListTile(
              title: const Text(
                "Storage Permission Needed",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                "Required to scan and play songs. Tap to open settings.",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              leading: const Icon(Icons.error_outline, color: Colors.redAccent),
              onTap: () {
                openAppSettings();
              },
            ),
          ListTile(
            title: const Text(
              "Manage Library Folders",
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              "Show/hide specific folders",
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
            onTap: () {
              Navigator.push(context, FolderManagementScreen.route());
            },
          ),
          SwitchListTile(
            title: const Text(
              "Hide Short Audio",
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              "Exclude files shorter than 60 seconds (e.g. WhatsApp audio)",
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            value: songProvider.filterShortSongs,
            onChanged: (value) {
              songProvider.toggleFilterShortSongs();
            },
            activeColor: Colors.deepPurpleAccent,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          const Divider(color: Colors.white10),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "About",
              style: TextStyle(
                color: Colors.deepPurpleAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            title: const Text(
              "Minimal Music Player",
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              "Version 1.0.0",
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}

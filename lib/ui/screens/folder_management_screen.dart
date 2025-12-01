import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/song_provider.dart';

class FolderManagementScreen extends StatelessWidget {
  const FolderManagementScreen({Key? key}) : super(key: key);

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (context) => const FolderManagementScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final songProvider = Provider.of<SongProvider>(context);
    final detectedFolders = songProvider.managedFolders;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Manage Folders",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.create_new_folder_outlined,
              color: Colors.white,
            ),
            onPressed: () => _pickFolder(context, songProvider),
          ),
        ],
      ),
      body: detectedFolders.isEmpty
          ? const Center(
              child: Text(
                "No folders detected",
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              itemCount: detectedFolders.length,
              itemBuilder: (context, index) {
                final folderPath = detectedFolders.keys.elementAt(index);
                final songCount = detectedFolders[folderPath];
                final isVisible = songProvider.isFolderVisible(folderPath);
                final folderName = folderPath.split('/').last;

                return CheckboxListTile(
                  title: Text(
                    folderName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    "$songCount songs • $folderPath",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  value: isVisible,
                  activeColor: Colors.deepPurpleAccent,
                  checkColor: Colors.white,
                  onChanged: (bool? value) {
                    songProvider.toggleFolderVisibility(folderPath);
                  },
                );
              },
            ),
    );
  }

  Future<void> _pickFolder(BuildContext context, SongProvider provider) async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        await provider.addManualFolder(selectedDirectory);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Added: $selectedDirectory"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error picking folder: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

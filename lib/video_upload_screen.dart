import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'main.dart'; // Import for ImagePickerService

class VideoUploadScreen extends StatefulWidget {
  final String uid; // Receive the uid here

  const VideoUploadScreen({Key? key, required this.uid}) : super(key: key);

  @override
  _VideoUploadScreenState createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  final ImagePickerService _pickerService = ImagePickerService();
  XFile? _videoFile;
  final TextEditingController _captionController = TextEditingController(); // Caption controller
  bool _isUploading = false;

  @override
  void dispose() {
    _captionController.dispose(); // Dispose the caption controller
    super.dispose();
  }

  Future<void> _pickVideo() async {
    XFile? video = await _pickerService.pickVideoFromGallery();
    if (video != null) {
      setState(() {
        _videoFile = video;
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (_videoFile != null) {
      setState(() {
        _isUploading = true;
      });

      try {
        Reference ref = FirebaseStorage.instance
            .ref()
            .child('videos/${DateTime.now().millisecondsSinceEpoch}.mp4');

        UploadTask uploadTask = ref.putData(await _videoFile!.readAsBytes());

        TaskSnapshot snapshot = await uploadTask;
        String downloadURL = await snapshot.ref.getDownloadURL();

        // Store video information in Firestore (with caption)
        DocumentReference videoRef = await FirebaseFirestore.instance.collection('videos').add({
          'url': downloadURL,
          'timestamp': DateTime.now(),
          'userId': widget.uid,
          'caption': _captionController.text,
        });

        // Automatically create the "comments" subcollection
        await videoRef.collection('comments').add({});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video uploaded successfully!')),
        );

        // Navigate back to VideoFeedScreen and trigger refresh
        Navigator.of(context).pop(true);
      } on FirebaseException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading video: $e')),
        );
      } finally {
        setState(() {
          _isUploading = false;
          _videoFile = null;
          _captionController.clear(); // Clear the caption field after upload
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Video')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _pickVideo,
              child: Text('Select Video'),
            ),
            if (_videoFile != null) ...[
              Text(_videoFile!.name),
              SizedBox(height: 20),

              Padding( // <--- Moved the caption input field inside this block
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _captionController,
                  decoration: InputDecoration(labelText: 'Caption'),
                ),
              ),

              ElevatedButton(
                onPressed: _isUploading ? null : _uploadVideo,
                child: _isUploading
                    ? CircularProgressIndicator()
                    : Text('Upload Video'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


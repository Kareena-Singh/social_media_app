import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class UploadPostScreen extends StatefulWidget {
  @override
  _UploadPostScreenState createState() => _UploadPostScreenState();
}

class _UploadPostScreenState extends State<UploadPostScreen> {
  final TextEditingController captionController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  XFile? _image;

  void pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedImage;
    });
  }
  void uploadPost() async {
    if (_image == null || captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Select image & add caption"))
      );
      return;
    }

    try {
      // Ensure user is logged in
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("User not authenticated!"))
        );
        return;
      }

      String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference ref = FirebaseStorage.instance.ref().child("posts/$fileName");

      print("Uploading file to: posts/$fileName");

      // Upload Image
      UploadTask uploadTask = ref.putFile(File(_image!.path));
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);

      if (snapshot.state == TaskState.success) {
        String imageUrl = await snapshot.ref.getDownloadURL();
        print("Image uploaded to: $imageUrl");

        // Generate unique post ID
        DocumentReference postRef = FirebaseFirestore.instance.collection("posts").doc();

        // Save to Firestore
        await postRef.set({
          "postId": postRef.id, // Unique Post ID
          "username": user.displayName ?? "Anonymous",
          "profilePic": user.photoURL ?? "",
          "userId": user.uid,
          "postImage": imageUrl,
          "caption": captionController.text,
          "likes": [], // Empty list for likes
          "timestamp": FieldValue.serverTimestamp(),
        });

        // Reset UI
        setState(() {
          _image = null;
          captionController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Post Uploaded Successfully!"))
        );
      } else {
        throw Exception("Upload failed.");
      }
    } catch (e) {
      print("Upload failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload Post")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: _image == null
                  ? Container(height: 150, color: Colors.grey[300], child: Icon(Icons.add_a_photo))
                  : Image.file(File(_image!.path), height: 150),
            ),
            TextField(
              controller: captionController,
              decoration: InputDecoration(labelText: "Caption"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: uploadPost,
              child: Text("Post"),
            ),
          ],
        ),
      ),
    );
  }
}
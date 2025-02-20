import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;
  EditProfileScreen({required this.userId});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  File? _image;
  String? _profilePicUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    DocumentSnapshot userDoc = await _firestore.collection("users").doc(widget.userId).get();
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        _usernameController.text = userData["username"] ?? "";
        _bioController.text = userData["bio"] ?? "";
        _profilePicUrl = userData["profilePic"];
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    String uid = _auth.currentUser!.uid;
    try {
      // Upload image to Firebase Storage if new image is selected
      if (_image != null) {
        TaskSnapshot uploadTask = await _storage.ref("profile_pics/$uid.jpg").putFile(_image!);
        _profilePicUrl = await uploadTask.ref.getDownloadURL();
      }

      // Update Firestore
      await _firestore.collection("users").doc(uid).update({
        "username": _usernameController.text.trim(),
        "bio": _bioController.text.trim(),
        "profilePic": _profilePicUrl,
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile updated successfully!")));
      Navigator.pop(context);
    } catch (e) {
      print("Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update profile.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _image != null
                    ? FileImage(_image!)
                    : _profilePicUrl != null
                    ? NetworkImage(_profilePicUrl!) as ImageProvider
                    : AssetImage('assets/avatar.png'),
                child: Icon(Icons.camera_alt, size: 30, color: Colors.white70),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "Username"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _bioController,
              decoration: InputDecoration(labelText: "Bio"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}

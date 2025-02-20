import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'EditProfileScreen.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;
  ProfileScreen({required this.userId});

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: StreamBuilder(
        stream: _firestore.collection("users").doc(userId).snapshots(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
            return Center(child: CircularProgressIndicator());
          }

          var user = snapshot.data!;
          var userData = user.data() as Map<String, dynamic>;

          return Column(
            children: [
              CircleAvatar(
                backgroundImage: userData.containsKey("profilePic") && userData["profilePic"] != null
                    ? NetworkImage(userData["profilePic"])
                    : AssetImage('assets/avatar.png') as ImageProvider, // Default image
                radius: 50,
              ),
              Text(userData["username"], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

              // ✅ FIX: Check if "bio" field exists before accessing it
              Text(userData.containsKey("bio") ? userData["bio"] : "No bio available"),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(userId: userId),
                    ),
                  );
                },
                child: Text("Edit Profile"),
              ),
              Divider(),
              Expanded(
                child: StreamBuilder(
                  stream: _firestore.collection("posts").where("userId", isEqualTo: userId).snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var post = snapshot.data!.docs[index];
                        var postData = post.data() as Map<String, dynamic>;

                        return postData.containsKey("imageUrl") && postData["imageUrl"] != null
                            ? Image.network(postData["imageUrl"], fit: BoxFit.cover)
                            : Image.asset('assets/no_image.jpg', fit: BoxFit.cover); // Default image
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

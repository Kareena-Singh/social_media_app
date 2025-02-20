import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PostDetailsScreen extends StatefulWidget {
  final String postId;
  const PostDetailsScreen({required this.postId});

  @override
  _PostDetailsScreenState createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController commentController = TextEditingController();

  void addComment() async {
    if (commentController.text.isNotEmpty) {
      await _firestore.collection("posts").doc(widget.postId).collection("comments").add({
        "userId": _auth.currentUser!.uid,
        "username": _auth.currentUser!.displayName,
        "comment": commentController.text,
        "timestamp": FieldValue.serverTimestamp(),
      });

      commentController.clear();
    }
  }

  void toggleLike(List likes) async {
    String uid = _auth.currentUser!.uid;
    if (likes.contains(uid)) {
      await _firestore.collection("posts").doc(widget.postId).update({
        "likes": FieldValue.arrayRemove([uid])
      });
    } else {
      await _firestore.collection("posts").doc(widget.postId).update({
        "likes": FieldValue.arrayUnion([uid])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Post Details")),
      body: StreamBuilder(
        stream: _firestore.collection("posts").doc(widget.postId).snapshots(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          var post = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(post["profilePic"]),
                ),
                title: Text(post["username"]),
              ),
              // Image.network(post["imageUrl"]),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(post["caption"]),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      post["likes"].contains(_auth.currentUser!.uid)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: post["likes"].contains(_auth.currentUser!.uid) ? Colors.red : Colors.grey,
                    ),
                    onPressed: () => toggleLike(post["likes"]),
                  ),
                  Text("${post["likes"].length} Likes"),
                ],
              ),
              Divider(),
              Expanded(
                child: StreamBuilder(
                  stream: _firestore.collection("posts").doc(widget.postId).collection("comments").orderBy("timestamp", descending: true).snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                    return ListView(
                      children: snapshot.data!.docs.map((comment) {
                        return ListTile(
                          title: Text(comment["username"]),
                          subtitle: Text(comment["comment"]),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(labelText: "Add a comment..."),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: addComment,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

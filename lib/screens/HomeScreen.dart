import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'PostDetailScreen.dart';
import 'UploadPostScreen.dart';
import 'ProfileScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _selectedIndex = 0;

  // List of screens for BottomNavigationBar
  final List<Widget> _screens = [
    HomeScreenContent(), // Separate widget for home feed
    UploadPostScreen(),
    ProfileScreen(userId: FirebaseAuth.instance.currentUser!.uid),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Upload"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// Separate widget for home feed content
class HomeScreenContent extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void toggleLike(String postId, List likes) async {
    String uid = _auth.currentUser!.uid;

    if (likes.contains(uid)) {
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayRemove([uid]),
      });
    } else {
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayUnion([uid]),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home Feed")),
      body: StreamBuilder(
        stream: _firestore.collection('posts').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> post = doc.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: post['profilePic'] != null && post['profilePic'].isNotEmpty
                            ? NetworkImage(post['profilePic'])
                            : AssetImage('Assets/avatar.png') as ImageProvider,
                      ),
                      title: Text(post['username']),
                    ),
                    post['postImage'] != null && post['postImage'].isNotEmpty
                        ? Image.network(
                      post['postImage'],
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset('Assets/no_image.jpg', height: 200, width: double.infinity, fit: BoxFit.cover);
                      },
                    )
                        : Image.asset('Assets/no_image.jpg', height: 200, width: double.infinity, fit: BoxFit.cover),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(post['caption']),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            post['likes'].contains(_auth.currentUser!.uid) ? Icons.favorite : Icons.favorite_border,
                            color: post['likes'].contains(_auth.currentUser!.uid) ? Colors.red : Colors.black,
                          ),
                          onPressed: () => toggleLike(doc.id, post['likes']),
                        ),
                        Text("${post['likes'].length} Likes"),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => PostDetailsScreen(postId: doc.id)),
                            );
                          },
                          child: Text("View Comments"),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

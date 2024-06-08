import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile.dart';
import 'main.dart'; // Import FirebaseAuthService and UserProfile
import 'video_feed_screen.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;// UID of the viewed profile user
  final VoidCallback? onRefresh;
  const ProfileScreen({Key? key, required this.uid,this.onRefresh}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool isFollowing = false; // State variable to track following status

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkFollowingStatus(); // Check following status initially
  }

  Future<void> _loadUserProfile() async {
    try {
      UserProfile? userProfile = await _authService.getUserProfile(widget.uid);
      setState(() {
        _userProfile = userProfile;
        _isLoading = false;
      });
    } catch (e) {
      // Handle errors (e.g., show a SnackBar)
      print('Error loading user profile: $e');
    }
  }

  Future<void> _checkFollowingStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final followingRef = FirebaseFirestore.instance
          .collection('following')
          .doc(currentUser.uid)
          .collection('userFollowing')
          .doc(widget.uid);

      final followingSnapshot = await followingRef.get();
      setState(() {
        isFollowing = followingSnapshot.exists;
      });
    }
  }

  // Method to toggle the follow/unfollow action
  Future<void> _toggleFollow() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final followingRef = FirebaseFirestore.instance
          .collection('following')
          .doc(currentUser.uid)
          .collection('userFollowing')
          .doc(widget.uid); // Use widget.uid (the viewed profile's UID)

      if (isFollowing) {
        await followingRef.delete(); // Unfollow
      } else {
        await followingRef.set({}); // Follow (empty map is fine here)
      }

      if (widget.onRefresh != null) {
        widget.onRefresh!();
      }

      setState(() {
        isFollowing = !isFollowing; // Toggle the state
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : (_userProfile != null
          ? Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... (Email and Username display)
            if (widget.uid == currentUserUid)
              ElevatedButton(
                onPressed: _toggleFollow,
                child: Text(isFollowing ? 'Unfollow' : 'Follow'),
              ),

            // Fetch and display posts
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('videos')
                    .where('userId', isEqualTo: widget.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final videos = snapshot.data!.docs;

                  return MasonryGridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      final videoUrl = videos[index]['url'];

                      return GestureDetector(
                        onTap: () {
                          // TODO: Navigate to video details screen
                        },
                        child: Image.network(
                          videoUrl,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      )
          : const Center(child: Text('Error loading profile'))),
    );
  }
}
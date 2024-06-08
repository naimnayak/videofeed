import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_profile.dart';
import 'video_upload_screen.dart';
import 'search_results_screen.dart';

class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({Key? key}) : super(key: key);

  @override
  _VideoFeedScreenState createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _videoData = [];

  String? currentUserId; // Define currentUserId as a member variable



  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeUserAndFetchVideos();
  }


  @override
  void dispose() {
    _searchController.dispose();
    _commentController.dispose();
    super.dispose();
  }


  Future<void> _initializeUserAndFetchVideos() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user == null) {
        // User not logged in, navigate to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        currentUserId = user.uid;
        // User logged in, fetch videos and set up stream
        await _fetchVideosAndUserData(user.uid);


        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
      }
    });
  }

  Future<void> _fetchVideosAndUserData(String uid) async {
    try {
      setState(() {
        _isLoading = true; // Show loading indicator while fetching
      });

      QuerySnapshot followingSnapshot = await FirebaseFirestore.instance
          .collection('following')
          .doc(currentUserId)
          .collection('userFollowing')
          .get();
      List<String> followingUserIds = followingSnapshot.docs.map((doc) => doc.id).toList();
      followingUserIds.add('currentUserId');

      // Fetch videos from Firestore
      QuerySnapshot videoSnapshot = await FirebaseFirestore.instance
          .collection('videos')
          .where('userId', whereIn: followingUserIds)
          .get();

      // Map video data with usernames
      _videoData = [];
      for (var videoDoc in videoSnapshot.docs) {
        String userId = videoDoc['userId'];
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

        _videoData.add({
          'video': videoDoc.data() as Map<String, dynamic>,
          'username': userDoc['username'] ?? 'Unknown User'
        });
      }

      setState(() {
        _isLoading = false; // Hide loading indicator after fetching
      });
    } on FirebaseException catch (e) {
      print('Error fetching videos: $e');
      setState(() {
        _isLoading = false; // Hide loading indicator in case of error
      });
      // Handle the error appropriately (e.g., show a SnackBar)
    }
  }

  Future<void> _addComment(String videoId, String commentText) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Handle the case where the user is not logged in (e.g., show a dialog)
        return;
      }

      final comment = Comment(
        text: commentText,
        authorUid: user.uid,
        timestamp: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .add(comment.toJson());
    } catch (e) {
      // Handle errors (e.g., show a SnackBar)
      print('Error adding comment: $e');
    }
  }
  void refreshFeed() {
    _initializeUserAndFetchVideos(); // Refresh the video data
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('VideoFeed'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchResultsScreen(searchController: _searchController,),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: () async {
              User? user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final shouldRefresh = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoUploadScreen(uid: user.uid),
                  ),
                );
                if (shouldRefresh == true) {
                  _fetchVideosAndUserData(user.uid);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please log in to upload videos')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () async {
              User? user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                // Pass the refreshFeed callback to ProfileScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      uid: user.uid,
                      onRefresh: refreshFeed,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please log in to view your profile')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _videoData.isEmpty
          ? const Center(child: Text("No videos uploaded yet."))
        : ListView.builder(
            itemCount: _videoData.length,
            itemBuilder: (context, index) {
              final video = _videoData[index]['video'];
              final username = _videoData[index]['username'];

              // Toggle Functionality (Moved outside the builder to preserve state)
              bool showComments = false;

              return StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VideoPlayerWidget(videoUrl: video['url']),

                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (video['caption'] != null) Text(video['caption']),
                            Text('Views: ${video['viewCount'] ?? 0}'),

                                SizedBox(height: 8), // Add some spacing
                                // Like, Comment, Share Buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    IconButton(icon: Icon(Icons.favorite_border), onPressed: () {}),
                                    IconButton(
                                      icon: Icon(Icons.comment),
                                      onPressed: () {
                                        setState(() {
                                          showComments = !showComments;
                                        });
                                      },
                                    ),
                                    IconButton(icon: Icon(Icons.share), onPressed: () {}),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Comment Section (Shown when showComments is true)
                                if (showComments)
                                  Column(
                                    children: [
                                      TextField(
                                        controller: _commentController,
                                        decoration: const InputDecoration(
                                          hintText: 'Add a comment...',
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          // ... (Your existing _addComment call)
                                        },
                                        child: const Text('Post'),
                                      ),
                                      StreamBuilder<QuerySnapshot>(
                                        stream: _firestore
                                            .collection('videos')
                                            .doc(video['id'])
                                            .collection('comments')
                                            .orderBy('timestamp', descending: true)
                                            .snapshots(),
                                        builder: (context, commentsSnapshot) {
                                          // ... (Display comments here)
                                          if (commentsSnapshot.hasError) {
                                            return Text('Error: ${commentsSnapshot.error}');
                                          }
                                          if (commentsSnapshot.connectionState == ConnectionState.waiting) {
                                            return const CircularProgressIndicator();
                                          }
                                          final commentDocs = commentsSnapshot.data!.docs;

                                          return Column(
                                            children: commentDocs.map((commentDoc) {
                                              final comment = Comment.fromJson(commentDoc.data() as Map<String, dynamic>);
                                              return FutureBuilder<DocumentSnapshot>(
                                                future: _firestore.collection('users').doc(comment.authorUid).get(),
                                                builder: (context, authorSnapshot) {
                                                  if (authorSnapshot.hasError) {
                                                    return Text('Error fetching author');
                                                  }
                                                  if (authorSnapshot.connectionState == ConnectionState.waiting) {
                                                    return const CircularProgressIndicator();
                                                  }
                                                  final authorData = authorSnapshot.data;
                                                  final authorName = authorData?['username'] ?? 'Unknown User';
                                                  return ListTile(
                                                    title: Text(comment.text),
                                                    subtitle: Text('$authorName - ${comment.timestamp.toString()}'),
                                                  );
                                                },
                                              );
                                            }).toList(),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
          );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  Future<void>? _initializeVideoPlayerFuture;
  UniqueKey _videoPlayerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayerFuture = _initializeVideo();
  }

  Future<void> _initializeVideo() async {

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    await _controller.initialize();
    _controller.setLooping(true);

    setState(() {
      _isInitialized = true;
      _videoPlayerKey = UniqueKey();
    });

    _controller.play(); // Autoplay after initialization
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _isInitialized
          ? AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      )
          : FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else {
            if (snapshot.hasError) {
              return const Center(
                child: Text("Video not found."),
              ); // Return error text
            } else {
              return VideoPlayer(_controller);
            }
          }
        },
      ),
    );
  }
}
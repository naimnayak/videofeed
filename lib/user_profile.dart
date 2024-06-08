import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String username;
  final String? profilePictureUrl; // Optional profile picture URL
  final String? bio;             // Optional bio
  // Add more fields as needed (e.g., followingCount, followerCount, etc.)

  UserProfile({
    required this.uid,
    required this.email,
    required this.username,
    this.profilePictureUrl,
    this.bio,
  });

  // Convert UserProfile object to a Map (for saving to Firestore)
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'username': username,
    'profilePictureUrl': profilePictureUrl,
    'bio': bio,
  };

  // Create UserProfile object from a Map (from Firestore data)
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    uid: json['uid'],
    email: json['email'],
    username: json['username'],
    profilePictureUrl: json['profilePictureUrl'],
    bio: json['bio'],
  );

  // Create UserProfile object from a Firestore DocumentSnapshot
  factory UserProfile.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id, // Use the document ID as the UID
      email: data['email'],
      username: data['username'],
      profilePictureUrl: data['profilePictureUrl'],
      bio: data['bio'],
    );
  }
}

// Comment Data Model
class Comment {
  final String text;
  final String authorUid;
  final DateTime timestamp;

  Comment({
    required this.text,
    required this.authorUid,
    required this.timestamp,
  });

  // Convert to/from Firestore data
  Map<String, dynamic> toJson() => {
    'text': text,
    'authorUid': authorUid,
    'timestamp': timestamp,
  };

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    text: json['text'],
    authorUid: json['authorUid'],
    timestamp: (json['timestamp'] as Timestamp).toDate(),
  );
}

// Potential Helper Functions (If Needed)
// You can add helper functions here to fetch user profiles, comments, etc.

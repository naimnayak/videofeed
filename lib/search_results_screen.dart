import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart'; // Import your ProfileScreen

class SearchResultsScreen extends StatefulWidget {
  final TextEditingController searchController;

  SearchResultsScreen({Key? key, required this.searchController}) : super(key: key);

  @override
  _SearchResultsScreenState createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  Stream<QuerySnapshot>? _usersStream;

  @override
  void initState() {
    super.initState();
    _updateSearchStream();
    widget.searchController.addListener(_updateSearchStream);
  }

  void _updateSearchStream() {
    final query = widget.searchController.text;
    setState(() {
      _usersStream = FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: query + '\uf8ff')
          .snapshots();
    });
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_updateSearchStream);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: widget.searchController, // Use the passed controller
          decoration: const InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _usersStream, // Use the updated stream
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          // Add this check to handle the case when there's no data
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No results found'));
          }

          final users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final username = userData['username'];
              return ListTile(
                title: Text(username),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(uid: users[index].id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

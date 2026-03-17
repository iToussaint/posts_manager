import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'post_model.dart';

void main() => runApp(const PostsManagerApp());

class PostsManagerApp extends StatelessWidget {
  const PostsManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Posts Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PostListScreen(),
    );
  }
}

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  final String apiUrl = "https://jsonplaceholder.typicode.com/posts";

  // READ: Fetch all posts [cite: 9]
  Future<List<Post>> fetchPosts() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Post.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load posts");
    }
  }

  // DELETE: Remove a post [cite: 13]
  Future<void> deletePost(int id) async {
    final response = await http.delete(Uri.parse('$apiUrl/$id'));
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post deleted successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Posts Manager")),
      body: FutureBuilder<List<Post>>(
        future: fetchPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final post = snapshot.data![index];
                return ListTile(
                  title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(post.body, maxLines: 2),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deletePost(post.id!),
                  ),
                  onTap: () => _showPostDialog(post: post), // View/Edit [cite: 10, 12]
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPostDialog(), // Create [cite: 11]
        child: const Icon(Icons.add),
      ),
    );
  }

  // Dialog for Creating or Editing Posts
  void _showPostDialog({Post? post}) {
    final titleController = TextEditingController(text: post?.title ?? "");
    final bodyController = TextEditingController(text: post?.body ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(post == null ? "Create Post" : "Edit Post"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: bodyController, decoration: const InputDecoration(labelText: "Body")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final newPost = Post(title: titleController.text, body: bodyController.text);
              if (post == null) {
                // CREATE Logic [cite: 11]
                await http.post(Uri.parse(apiUrl), body: jsonEncode(newPost.toJson()));
              } else {
                // EDIT Logic [cite: 12]
                await http.put(Uri.parse('$apiUrl/${post.id}'), body: jsonEncode(newPost.toJson()));
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
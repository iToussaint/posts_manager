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
      debugShowCheckedModeBanner: false,
      title: 'Posts Manager',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
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

  Future<List<Post>> fetchPosts() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Post.fromJson(item)).toList();
      }
      throw Exception("Failed to load posts");
    } catch (e) {
      throw Exception("Network Error: Check your connection");
    }
  }

  Future<void> deletePost(int id) async {
    final response = await http.delete(Uri.parse('$apiUrl/$id'));
    if (response.statusCode == 200) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post deleted successfully"), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Posts Manager", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: FutureBuilder<List<Post>>(
        future: fetchPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("${snapshot.error}", style: const TextStyle(color: Colors.red)));
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final post = snapshot.data![index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(post.title, 
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _confirmDelete(post.id!),
                    ),
                    onTap: () => _showPostDialog(post: post),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPostDialog(),
        label: const Text("New Post"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Post?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(onPressed: () { Navigator.pop(context); deletePost(id); }, 
          child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _showPostDialog({Post? post}) {
    final titleController = TextEditingController(text: post?.title ?? "");
    final bodyController = TextEditingController(text: post?.body ?? "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post == null ? "Create New Post" : "Edit Post", 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: bodyController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                onPressed: () async {
                  if (titleController.text.isEmpty) return;
                  Navigator.pop(context);
                },
                child: const Text("Save Post"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
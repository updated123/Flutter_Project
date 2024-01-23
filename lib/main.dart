import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Repositories',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> repositories = [];

  @override
  void initState() {
    super.initState();
    _fetchRepositories();
  }

  Future<void> _fetchRepositories() async {
  final Uri uri = Uri.parse('https://api.github.com/users/freeCodeCamp/repos');
  final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        repositories = List<Map<String, dynamic>>.from(data);
      });

      // Now that we have the repositories, fetch last commit for each
      for (final repo in repositories) {
        await _fetchLastCommit(repo['owner']['login'], repo['name']);
      }
    } else {
      // Handle error
      print('Failed to fetch repositories: ${response.statusCode}');
    }
  }

  Future<void> _fetchLastCommit(String owner, String repoName) async {
  final Uri uri = Uri.parse('https://api.github.com/repos/$owner/$repoName/commits');
  final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> commits = json.decode(response.body);
      final lastCommitData = commits.isNotEmpty ? commits[0] : null;

      setState(() {
        final repoIndex = repositories.indexWhere((repo) => repo['name'] == repoName);
        if (repoIndex != -1) {
          repositories[repoIndex]['lastCommit'] = lastCommitData;
        }
      });
    } else {
      print('Failed to fetch last commit for $repoName: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GitHub Repositories'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (repositories.isEmpty) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    return ListView.builder(
      itemCount: repositories.length,
      itemBuilder: (context, index) {
        final repo = repositories[index];
        return ListTile(
          title: Text(repo['name']),
          subtitle: Text(repo['description'] ?? 'No description available'),
          trailing: repo.containsKey('lastCommit')
              ? Text('Last Commit: ${repo['lastCommit']['commit']['author']['name']}')
              : null,
        );
      },
    );
  }
}

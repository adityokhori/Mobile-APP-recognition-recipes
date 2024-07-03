import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'newsmodel.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsApi extends StatefulWidget {
  const NewsApi({super.key});

  @override
  State<NewsApi> createState() => _NewsApiState();
}

class _NewsApiState extends State<NewsApi> {
  List<NewsArticle> _articles = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _pageSize = 15;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchNews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchNews() async {
    final url =
        'https://newsapi.org/v2/everything?&q=healthy%20foods&page=$_currentPage&pageSize=$_pageSize&apiKey=24de81ed1a404519bb9504917f9f295f';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List articlesJson = jsonData['articles'];
        setState(() {
          for (var json in articlesJson) {
            // Validate data
            if (json['source']['id'] == null &&
                json['source']['name'] == '[Removed]' &&
                json['author'] == null &&
                json['title'] == '[Removed]' &&
                json['description'] == '[Removed]' &&
                json['url'] == 'https://removed.com' &&
                json['urlToImage'] == null &&
                json['publishedAt'] == '1970-01-01T00:00:00Z' &&
                json['content'] == '[Removed]') {
              continue; // Skip data
            }
            _articles.add(NewsArticle.fromJson(json));
          }

          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      print(e);
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500 &&
        !_isLoadingMore &&
        !_isLoading) {
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });
      _fetchNews();
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _articles.length,
                    itemBuilder: (context, index) {
                      final article = _articles[index];
                      return InkWell(
                        onTap: () => _launchURL(article.url),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Stack(
                            children: [
                              // Image
                              article.urlToImage.isNotEmpty
                                  ? Image.network(
                                      article.urlToImage,
                                      width: MediaQuery.of(context).size.width,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: MediaQuery.of(context).size.width,
                                      height: 200,
                                      color: Colors.grey,
                                      child: const Center(child: Text('No Image')),
                                    ),
                              // Title and Subtitle
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  color: Colors.black.withOpacity(0.6),
                                  padding: const EdgeInsets.all(2.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        article.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        article.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }
}

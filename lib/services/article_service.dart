import '../constants.dart';
import 'dart:convert';
import 'package:http/http.dart';

class ArticleService {
  List<dynamic> listData = [];
  Map mapData = {};

  Future<List<dynamic>> getAllArticles() async {
    Response response = await get(Uri.parse('$host/api/articles'));

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      // Handle the wrapped response structure: {"articles": [...]}
      listData = responseData['articles'] ?? responseData;
      
      return listData;
    } else {
      throw Exception('Failed to load data: ${response.statusCode} ${response.body}');
    }
  }

  Future<Map> createArticle(dynamic article) async {
    final response = await post(
      Uri.parse('$host/api/articles'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(article),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      mapData = jsonDecode(response.body);
      return mapData;
    } else {
      throw Exception(
        'Failed to create article: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<Map> updateArticle(String id, dynamic article) async {
    final response = await put(
      Uri.parse('$host/api/articles/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(article),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      mapData = jsonDecode(response.body);
      return mapData;
    } else {
      throw Exception(
        'Failed to update article: ${response.statusCode} ${response.body}',
      );
    }
  }
}

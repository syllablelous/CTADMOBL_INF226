import '../constants.dart';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:flutter/services.dart';
import '../models/article_model.dart';

class ArticleService {
  List<Article> listData = [];

  Future<List> getAllArticles() async {
    Response response = await get(Uri.parse('$host/posts'));

    if (response.statusCode == 200) {
      listData = jsonDecode(response.body);

      return listData;
    } else {
      throw Exception('Failed to load data');
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

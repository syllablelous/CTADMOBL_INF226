import '../constants.dart';
import 'dart:convert';
// import 'package:http/http.dart';
import 'package:flutter/services.dart';

class ArticleService {
  List listData = [];

  Future<List> getAllArticles() async {
    try {
      // Loding fromtneh JSON file for now. Backend integration will be at a letere date.
      final String response = await rootBundle.loadString(
        'assets/articles.json',
      );
      listData = jsonDecode(response);
      return listData;

      // Response response = await get(Uri.parse('$host/posts'));
      //
      // if (response.statusCode == 200) {
      //   listData = jsonDecode(response.body);
      //
      //   return listData;
      // } else {
      //   throw Exception('Failed to load data');
      // }
    } catch (e) {
      throw Exception('Failed to load articles: $e');
    }
  }
}

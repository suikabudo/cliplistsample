import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/driver.dart' as driver;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:http/http.dart';

class ClipListModel extends ChangeNotifier {
  List<String> cliplist = [];
  List<String> bookmark = [];
  List<PageData> pagedataList = [];

  Future<List<PageData>> request() async {
    if (pagedataList != null) {
      pagedataList.removeRange(0, pagedataList.length);
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    cliplist = prefs.getStringList("CLIPLIST");

    for (int i = 0; i < cliplist.length; i++) {
      PageData tmpPageData = new PageData();
      tmpPageData = await fetch(cliplist[i]);
      pagedataList.add(tmpPageData);
    }
    notifyListeners();
    return pagedataList;
  }

  Future<void> trash(deletePageData) async {
    if(pagedataList!= null){
      pagedataList.remove(deletePageData);
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    cliplist = prefs.getStringList("CLIPLIST");
    cliplist.remove(deletePageData.url);
    await prefs.setStringList("CLIPLIST", cliplist);

    notifyListeners();
  }

  _validateUrl(String url) {
    if (url?.startsWith('http://') == true ||
        url?.startsWith('https://') == true) {
      return url;
    }
    else {
      return 'http://$url';
    }
  }

  Future<PageData> fetch(url) async {
    final client = Client();
    final response = await client.get(_validateUrl(url));
    final document = parse(response.body);

    PageData tmpPageData = new PageData();
    tmpPageData.url = url;

    var elements = document.getElementsByTagName('meta');
    //final linkElements = document.getElementsByTagName('link');

    for (int i = 0; i < elements.length; i++) {
      if (elements[i].attributes['property'] == 'og:site_name') {
        tmpPageData.sitename = elements[i].attributes['content'];
        continue;
      }
      if (elements[i].attributes['property'] == 'og:title') {
        tmpPageData.title = elements[i].attributes['content'];
        continue;
      }
      if (elements[i].attributes['property'] == 'og:image') {
        tmpPageData.image = elements[i].attributes['content'];
        continue;
      }
    }
    return tmpPageData;
  }

}


class PageData{
  String sitename;
  String title;
  String image;
  String url;
}

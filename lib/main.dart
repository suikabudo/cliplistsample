import 'package:flutter/material.dart';
import 'cliplist_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    //エラーは出ないのですがゴミ箱アイコン(ClipListModelのtrashメソッド）を実行してもリストの表示が変わりません
      ChangeNotifierProvider<ClipListModel>(
          create: (context) => ClipListModel(),
          child:MyApp()
      ));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    savedata();

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ClipScreen(),
    );
  }
}
class ClipScreen extends StatelessWidget {
  const ClipScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("クリップリスト"),
        ),
        //以下の位置でコード①にすると例のエラーとなってしまったため、さらに上位のrunAppにてChangeNotifierProviderを記載しました
        // body: ChangeNotifierProvider(           // 追加
        // create: (context) => ClipListModel(), //
        body: Center(
            child: Container(
                child: FutureBuilder<List<PageData>>(
                    future: Provider.of<ClipListModel>(context, listen: false).request(), //コード①
                    // future:ClipListModel().request(),
                    builder: (context, dataSnapshot) {
                      if (dataSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        // 非同期処理未完了 = 通信中
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (dataSnapshot.error != null) {
                        // エラー
                        return Center(
                            child: Text('エラーが発生しました。一度アプリを終了し再度起動してください')
                        );
                      }

                      if (dataSnapshot.data.length == 0) {
                        return Center(
                            child: Text('データがありません')
                        );
                      }
                      return clipListContents(dataSnapshot.data);
                    })))
    );
  }
}



void savedata()async{
  SharedPreferences saveprefs = await SharedPreferences.getInstance();
  List<String> tmpData = ["https://qiita.com/","https://tenki.jp/","https://news.yahoo.co.jp/"];
  await saveprefs.setStringList("CLIPLIST", tmpData);

}


Widget clipListContents(List<PageData> cliplistdata) {
  return ListView.builder(
    physics: AlwaysScrollableScrollPhysics(),
    itemCount: cliplistdata.length,
    itemBuilder: (lctx, index) =>
        Consumer<ClipListModel>(
            builder: (context, clipdata, child) {
              return Padding(
                  padding: const EdgeInsets.only(
                      right: 8.0, left: 8.0),
                  child: InkWell(
                    onTap: () {
                      launch(cliplistdata[index].url);
                    },
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment
                            .spaceBetween,
                        children: <Widget>[
                          Image.network(
                              cliplistdata[index].image,
                              height: 100.0, width: 100.0),
                          new Expanded(
                              child: new Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Padding(
                                      padding:
                                      EdgeInsets.only(
                                          left: 8.0),
                                      child: Text(
                                          (cliplistdata
                                          [index]
                                              .sitename),
                                          style:
                                          TextStyle(
                                              fontSize: 18)),
                                    ),
                                    Padding(
                                      padding:
                                      EdgeInsets.only(
                                          left: 12.0),
                                      child: Text(
                                          cliplistdata
                                          [index]
                                              .title,
                                          style: TextStyle(
                                              color: Colors
                                                  .black38)),
                                    )
                                  ])),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              ClipListModel().trash(
                                  cliplistdata[index]);
                              showDialog(
                                context: lctx,
                                builder: (_) {
                                  return AlertDialog(
                                    content: Text(
                                        "クリップリストから削除します"),
                                    actions: <Widget>[
                                      FlatButton(
                                          onPressed: () =>
                                          Navigator
                                              .of(lctx)
                                              .pop //OKボタンをクリックしてもダイアログが閉じないので一旦OKを消している
                                      )
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ]),
                  )
              );
            }),
  );
}
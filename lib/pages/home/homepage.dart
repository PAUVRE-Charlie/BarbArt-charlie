import 'package:barbart/api/APIValues.dart';
import 'package:barbart/api/structures.dart';
import 'package:barbart/components/AbstractPageComponent.dart';
import 'package:barbart/components/SocialPostItem.dart';
import 'package:barbart/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../main.dart';

// ignore: must_be_immutable
class HomePage extends AbstractPageComponent{
  HomePage({Key key}) : super(key: key);

  @override
  String get name => "Home";

  @override
  Icon get icon => Icon(Icons.home, color: Colors.white);

  @override
  Image get logo => Image(image: AssetImage("assets/logo_clipped.png"));

  @override
  State<StatefulWidget> createState() => _HomePageState();

}

class _HomePageState extends State<HomePage> {

  bool _addingPost = false;
  bool _admin = true;
  List<ASocialPost> posts;

  @override
  void initState() {
    super.initState();
    posts = gAPI.socialPosts.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: <Widget>[
          Container(
            child: posts.length > 0 ?
              RefreshIndicator(
                onRefresh: () async {
                  gAPI.update(APIFlags.SOCIAL_POSTS, onUpdateDone: () {
                    this.setState(() {});
                  });
                },
                child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0, bottom: 260),
                  itemCount: posts.length,
                  itemBuilder: (BuildContext context, int index) {
                    return SocialPostItem(socialPost: posts[index], addingPost: _addingPost, index: index );
                  },
                ),
              ) : Center(
              child: Text("Waiting for server..."),
            ),
          ),
          /* Floating Button */
          (_addingPost || !_admin) ? Container() : Positioned(
              bottom: 297,
              right: 10,
              child: FloatingActionButton(
                backgroundColor: kPrimaryColor,
                child: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    _addingPost = true;
                    ASocialPost newPost = new ASocialPost(title: 'Title', body: 'This is the body of your post', clientUUID: gAPI.selfClient.uuid, datetime: DateTime.now(), id: -1, nbrComments: 0, nbrLikes: 0, tags: [], selfClientLiked: false);
                    posts = [newPost, ...posts];
                  });
                },
              )
          ),
        ],
      ),
    );
  }

}
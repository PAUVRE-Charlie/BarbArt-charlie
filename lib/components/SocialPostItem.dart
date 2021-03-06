import 'dart:io';
import 'dart:math';

import 'package:barbart/api/APIManager.dart';
import 'package:barbart/api/structures.dart';
import 'package:barbart/components/DeleteConfirmationComponent.dart';
import 'package:barbart/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tags/flutter_tags.dart';
import 'package:image_picker/image_picker.dart';
import 'package:expandable/expandable.dart';

import '../main.dart';
import '../utils.dart';
import 'TextIcon.dart';

class _SocialPostItemUIState {
  bool  liked = false,
      commented = false;

  bool pending = false;
}

class SocialPostItem extends StatefulWidget {
  final ASocialPost socialPost;
  final bool addingPost;
  final int index;

  const SocialPostItem({Key key, this.socialPost, this.addingPost, this.index}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SocialPostItemState();
}

class SocialPostItemState extends State<SocialPostItem> {
  _SocialPostItemUIState UIState = new _SocialPostItemUIState();

  /* TODO: change this part */
  bool _admin = true;
  List<String> adminActions = [
    "Delete", "Tags", "MainText"
  ];

  bool _editingMainText = false, _editingTags = false;
  bool _addingPost;

  TextEditingController _tagController;
  TextEditingController _mainTextController;
  ExpandableController _expandableController;

  /* END todo */

  @override
  void initState() {
    super.initState();

    /* Fetching if the client has liked this post */
    widget.socialPost.hasLiked(
        gAPI.selfClient,
        onConfirmed: (bool liked) {
          if(this.mounted) {
            this.setState(() {
              this.UIState.liked = liked;
            });
          }
        }
    );

    /* Updating when the number of likes has been updated */
    widget.socialPost.nbrLikesNotifier.addListener(() {
      if(this.mounted) this.setState(() {}); // Redrawing this post
    });

  }

  @override
  Widget build(BuildContext context) {
    GlobalKey<_EditPostItemState> editBodyItemKey = new GlobalKey<_EditPostItemState>();
    GlobalKey<_ClickToEditTextState> clickToEditKey = new GlobalKey<_ClickToEditTextState>();

    AClient author = gAPI.clientFromUUID(widget.socialPost.clientUUID);

    _addingPost = widget.addingPost;

    _tagController = TextEditingController(text: '');
    _mainTextController = TextEditingController(text: widget.socialPost.body);
    _expandableController = ExpandableController(initialExpanded: false);

    return Container(
        margin: EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: <Widget>[
            /* Post Header */
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[

                    CircleAvatar(
                      radius: 25,
                      backgroundImage: author.avatar,
                      backgroundColor: kDefaultCircleAvatarBackgroundColor,
                    ),
                    SizedBox(width: 10,),

                    /* Header infos */
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(author.firstname + " " + author.lastname, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(ago(widget.socialPost.datetime) + " ago.", style: TextStyle(fontSize: 15, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                /*! _admin ? Container() : PopupMenuButton(
                icon: Icon(Icons.more_horiz), //TODO: Implements onPressed or delete the widget
                itemBuilder: (BuildContext context){
                  return adminActions.map((String actionStr) {
                    return PopupMenuItem<String>(
                        value: actionStr,
                        child: Text(actionStr)
                    );
                  }).toList();
                },
                onSelected: (str) async{
                  if (str == "Delete"){
                    print("delete item ${widget.socialPost.title}"); // TODO: Implements function to delete this post
                  }
                  else if (str == "Tags") {
                    print("tags item number ${widget.socialPost.title}"); // TODO: Implements function to change post in server
                    setState(() {
                      _editingTags = true;
                    });
                  }
                  else if (str == "MainText"){ // TODO: Implements function to change post in server
                    print("text item number ${widget.socialPost.title}");
                    setState(() {
                      _editingMainText = true;
                    });
                  }
                },
              )*/
                Row(
                  children: <Widget>[
                    ! (_addingPost && widget.index ==0) ? Container() : IconButton(
                      icon: Icon(Icons.add_circle, color: Colors.green),
                      onPressed: (){
                        setState(() {
                          print("add item ${widget.socialPost.title}"); // TODO: Implements function to add this post

                          DeleteConfirmationComponent.show(context, title: Text("Do you want to add this post ?", textAlign: TextAlign.center,));
                        });

                      },
                      padding: EdgeInsets.all(5),
                    ),
                    ! _admin ? Container() : IconButton(
                      icon: Icon(Icons.cancel, color: Colors.red),
                      onPressed: (){
                        setState(() {
                          print("delete item ${widget.socialPost.title}"); // TODO: Implements function to delete this post

                          DeleteConfirmationComponent.show(context, title: Text("Do you want to delete this post ?", textAlign: TextAlign.center,));
                        });

                      },
                      padding: EdgeInsets.all(5),
                    ),

                  ],
                )


              ],
            ),

            /* Post tags */
            Container(
              margin: EdgeInsets.only(top: 10, bottom: 0),
              child: Tags(
                  itemCount: widget.socialPost.tags.length,
                  textField: _admin ? TagsTextField(
                    autofocus: false,
                    textStyle: TextStyle(fontSize: 14),
                    onSubmitted: (String str) {
                      // Add item to the data source.
                      setState(() {
                        // TODO : add str to server
                        print(str);
                      });
                    },
                  ): null,
                  itemBuilder: (int tagIndex) {
                    return ItemTags(
                      key: Key('itemtag' + tagIndex.toString()),
                      index: tagIndex,
                      title: widget.socialPost.tags[tagIndex],
                      color: kPrimaryColor,
                      elevation: 3,
                      textColor: Colors.white,
                      active: false,
                      pressEnabled: _admin,
                      textStyle: TextStyle(fontSize: 14),
                      textActiveColor: Colors.white,
                      activeColor: kPrimaryColor,
                      highlightColor: kPrimaryColor,
                      removeButton: _admin ? ItemTagsRemoveButton(
                        onRemoved: (){
                          // Remove the item from the data source.
                          setState(() {
                            //TODO : remove from server
                            print("remove "+ widget.socialPost.tags[tagIndex]);
                          });
                          //required
                          return true;
                        },
                      ) : null,

                    );
                  }
              ),
            ),

            /* Post body (main text) */
            ExpandableNotifier(
              controller: _expandableController,
              child: Expandable(
                collapsed: ExpandableButton(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: <Widget>[
                        Text(widget.socialPost.body, maxLines: 5, overflow: TextOverflow.ellipsis,),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('Click to see more', style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ),
                  )
                ),
                expanded: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: <Widget>[
                      !_admin ? Text(widget.socialPost.body): Container(
                        width: deviceSize(context).width,
                        padding: EdgeInsets.all(10.0),
                        child: Column(
                          children: <Widget>[
                            ClickToEditText(clickToEditKey: clickToEditKey, editingMainText: _editingMainText,),
                            TextField(
                                controller: _mainTextController,
                                minLines: 1,
                                maxLines: 100,
                                style: TextStyle(fontSize: 13.5),
                                onTap: (){
                                  print("editing");
                                  clickToEditKey.currentState.setState(() {clickToEditKey.currentState._editingMainText = true;});
                                  editBodyItemKey.currentState.setState(() {editBodyItemKey.currentState._editingMainText = true;});
                                },
                                decoration:new InputDecoration(
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,)
                            ),
                            EditPostItem(
                              editBodyItemKey: editBodyItemKey,
                              editingMainText: _editingMainText,
                              onCancel: (){
                                setState(() {
                                  _mainTextController.clear();
                                  _mainTextController = TextEditingController(text: widget.socialPost.body);
                                  _editingMainText = false;
                                });},
                              onSubmit: (){
                                setState(() {
                                  // TODO: change text in server
                                  _mainTextController.clear();
                                  _mainTextController = TextEditingController(text: widget.socialPost.body);
                                  _editingMainText = false;
                                });
                              },
                            ),
                          ],
                        ),// TEXT
                      ),

                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Stack(
                          children: [
                            Align(
                              child: false ? SizedBox(
                                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor), strokeWidth: 7, ),
                                  width: 160,
                                  height: 160
                              ) : null,
                              alignment: Alignment.center,
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: Stack(
                                children: <Widget>[
                                  Center(
                                    child: Image(
                                      image: AssetImage('./assets/header_background_raw.png'),
                                      height: 150,
                                    ),
                                  ),
                                  !_admin ? Container() :Container(
                                    height: 150,
                                    child: Align(
                                        alignment: Alignment.bottomRight,

                                        /* Edit image button */
                                        child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: false ? Colors.grey : kPrimaryColor,
                                            ),

                                            child: IconButton(
                                              icon:  const Icon(Icons.edit, color: Colors.white),
                                              onPressed: () async {

                                                /* ####################################### */
                                                /* ###### HERE IMAGE UPDATE ACTION ###### */
                                                /* ####################################### */

                                                if(false) return; // Forbid to change the image if one is already being uploaded.

                                                PickedFile file = await ImagePicker().getImage(source: ImageSource.gallery);
                                                if(file == null) return;

                                                // TODO: implement registerImage
                                                /*gAPI.registerImage(
                                                      avatarFile: File(file.path),

                                                      onConfirmed: () {
                                                        // Changing UI to indicate that the image is changed
                                                        this.setState(() {
                                                        });
                                                      }
                                                  );

                                                  // Changing UI to indicate that the image is changing
                                                  this.setState(() {
                                                  });*/
                                              },
                                            )
                                        )
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ExpandableButton(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: Text('Click to see less', style: TextStyle(color: Colors.grey),),
                          )
                      ),
                    ],
                  ),
                )
              ),
            ),
            /* Interactions bar bellow the post body (Likes, Comments, ...) */
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[

                  // Like button
                  TextIcon(
                    padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    width: 120 + 10*(log(widget.socialPost.nbrLikesNotifier.value) / ln10).floorToDouble(),
                    animate: true,

                    checked: this.UIState.liked,

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: Colors.grey[400], width: 0.5),
                    ),

                    icon: Icon(Icons.thumb_up,),

                    text: Text(widget.socialPost.nbrLikesNotifier.value.toString() + ' likes'),

                    // Like button pressed
                    onPressed: () {

                      /* ################################### */
                      /* ######## HERE LIKE ACTION ######### */
                      /* ################################### */

                      // Notifying the server. If the request failed, we change back the UI.
                      widget.socialPost.setLike(
                        gAPI.selfClient,
                        liked: !UIState.liked, // We request the opposite
                        onConfirmed: (bool success) {
                          if(this.mounted)  this.setState(() { // Always set state regardless of the success state because we have to update the the number of likes if succeeded, and update the UIState if the request was unsuccessful.
                            if(!success) this.UIState.liked = !this.UIState.liked; // If it failed, change back the UI that has been changed the moment the user clicked on the button.
                          });
                        },

                        changeValueOnTrigger: true,
                      );

                      // Update the UI regardeless of the server's reaction in case of bad connection. We want the UI to be responsive.
                      // Note: It only updates the like button and not the text !
                      // Note : Do this after the request so that the UI state remains the former when calling setLike
                      this.setState(() {
                        this.UIState.liked = !this.UIState.liked;
                      });

                    },
                  ),

                  // Comments button
                  /*TextIcon(
                  icon: Icon(
                    Icons.chat_bubble,
                    color: Colors.grey[400],
                  ),
                  text: Text(socialPost.nbrComments.toString() + ' comments'),
                  onPressed: () {
                    // TODO: implement the comments system
                  }
                )*/

                ],
              ),
            ),
            Divider(),

          ],
        )
    );
  }

}

class EditPostItem extends StatefulWidget{

  final bool editingMainText;
  final void Function() onSubmit;// TODO:  will be a Future<bool>
  final void Function() onCancel; // TODO:  will be a Future<bool>

  final GlobalKey<_EditPostItemState> editBodyItemKey;

  const EditPostItem({this.editBodyItemKey, this.editingMainText = false, this.onSubmit, this.onCancel}) : super(key: editBodyItemKey);

  @override
  _EditPostItemState createState() => _EditPostItemState();
}

class _EditPostItemState extends State<EditPostItem> {

  bool _editingMainText;

  @override
  void initState() {
    _editingMainText = widget.editingMainText;
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return (_editingMainText ? Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.cancel, color: Colors.red),
          onPressed: (){
            widget.onCancel();
          },
          padding: EdgeInsets.all(5),
        ),
        IconButton(
          icon: Icon(Icons.check_circle, color: Colors.green),
          onPressed: (){
            widget.onSubmit();
          },
          padding: EdgeInsets.all(5),
        )
      ],
    ): Container());
  }
}

class ClickToEditText extends StatefulWidget{

  final bool editingMainText;
  final GlobalKey<_ClickToEditTextState> clickToEditKey;

  const ClickToEditText({this.clickToEditKey, this.editingMainText}) : super(key: clickToEditKey);


  @override
  _ClickToEditTextState createState() => _ClickToEditTextState();
}

class _ClickToEditTextState extends State<ClickToEditText> {

  bool _editingMainText;

  @override
  void initState() {
    _editingMainText = widget.editingMainText;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _editingMainText ? Container() : Padding(
      padding: EdgeInsets.only(bottom: 5),
      child: Text(_editingMainText ? ' ' : 'Click to edit', style: TextStyle(color: Colors.grey), textAlign: TextAlign.left,),
    );
  }
}
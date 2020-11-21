import 'dart:async';

import 'package:barbart/api/structures.dart';
import 'package:barbart/components/TextIcon.dart';
import 'package:barbart/components/messageloadingbutton.dart';
import 'package:barbart/constants.dart';
import 'package:barbart/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:intl/intl.dart';

import '../../main.dart';

class DetailsBody extends StatefulWidget {
  final AEvent event;

  const DetailsBody({Key key, @required this.event}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new _DetailsBodyState();
}

class _DetailsBodyState extends State<DetailsBody> {
  bool localGoing = false; // true when UI shows that the user is going to the event, false when the user is not going.
  bool pending = false; // If we are still waiting for the server... True by default as there is the going request right at the beginning.


  bool _admin = true;
  bool _moderator = false;
  bool _editingDescription = false;
  TextEditingController _mainTextController;

  @override
  void initState() {
    super.initState();

    pending = true;
    /* Fetching if the client is going */
    widget.event.isGoing(
        gAPI.selfClient,
        onConfirmed: (bool going) {
          this.setState(() {
            localGoing = going;
            pending = false;
          });
        }
    );

    widget.event.nbrPeopleGoingNotifier.addListener(() {this.setState(() {});}); // rebuilding when the number of people updated!
    _mainTextController = TextEditingController(text: widget.event.description);
  }


  @override
  Widget build(BuildContext context) {

    GlobalKey<_EditPostItemState> editBodyItemKey = new GlobalKey<_EditPostItemState>();
    GlobalKey<_ClickToEditTextState> clickToEditKey = new GlobalKey<_ClickToEditTextState>();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // The localGoing state is now the state AT THE MOMENT THE BUTTON WAS PRESSED !

          if(pending) // Do nothing, we are waiting for the server.
            return;

          /* ########################### */
          /* #### HERE GOING ACTION #### */
          /* ########################### */

          // Requesting server, asynchronously with a callback function when we get the response;
          widget.event.setGoing(
            gAPI.selfClient,
            going: !localGoing, // We request the opposite of the current state.
            onConfirmed: (success) {
              if(!success) {
                // Inform the user that there was an error
                Scaffold.of(context).showSnackBar(SnackBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  content: Container(
                    margin: EdgeInsets.symmetric(horizontal: 3),
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),

                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(6),
                    ),

                    child: const Text("Can't register ! There are most likely no slots left.", textAlign: TextAlign.center,style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ));
              }
              this.setState(() {
                if(success) localGoing = !localGoing;
                pending = false;
              });
            }
          );

          // Setting as pending
          setState(() {
            pending = true;
          });
        },

        child: (pending) ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),) : const Icon(Icons.directions_walk, color: Colors.white),
        backgroundColor: localGoing ? Colors.green : Colors.grey,
      ),

      body: ListView(
        children: <Widget>[

          /* Event Image */
          Hero(
            tag: 'event: ${widget.event.id}',
            child: ClipPath(
              clipper: _mainImageClipper(),
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: widget.event.image,
                    fit: BoxFit.cover,
                  )
                ),
              )
            )
          ),

          /* Event title */
          Column(
            children: <Widget>[
              Stack(
                children: <Widget>[
                  Hero(
                    tag: 'eventText: ${widget.event.id}',
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: ' ${widget.event.title} \n',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 30,
                          )
                        )
                      )
                    ),
                  ),
                  (_admin || _moderator) ? Positioned(
                    right: 30,
                    child: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: (){
                        setState(() {
                          EditEventComponent.show(
                            context,
                            title: Text("Editing this event"),
                            event: widget.event,
                          );
                        });
                      },
                    ),
                  ) : Container()
                ],
              ),

              /* Event date */
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(right: 5),
                    child: Icon(Icons.calendar_today, color: Colors.black),
                  ),
                  RichText(
                    text: TextSpan(
                      text: DateFormat("EEEE dd/MM").format(widget.event.dateTimeBegin) + " : " + timeToString(widget.event.dateTimeBegin),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      )
                    )
                  )
                ],
              ),

              /* Event infos */
              Container(
                margin: EdgeInsets.only(top: 25),
                padding: EdgeInsets.all(5.0),
                width: deviceSize(context).width * 0.75,
                decoration: BoxDecoration(
                  border: Border(
                    top:    BorderSide(color: Colors.grey, width: 1, style: BorderStyle.solid),
                    bottom: BorderSide(color: Colors.grey, width: 1, style: BorderStyle.solid),
                  ),
                ),

                /* Row here ! */
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[

                    /* Event number of people going */
                    TextIcon(
                      icon: Icon(Icons.check_circle, color: Colors.green),
                      text: Text(widget.event.nbrPeopleGoingNotifier.value.toString(), style: TextStyle(fontSize: 20)),
                    ),

                    /* Event Place */
                    TextIcon(
                      icon: Icon(Icons.place),
                      text: Text(widget.event.location.toString(), style: TextStyle(fontSize: 20)),
                    ),

                    /* Event number of places available */
                    TextIcon(
                      icon: Icon(Icons.event_seat, color: Colors.brown[400]),
                      text: Text(widget.event.nbrPlaceAvailable.toString(), style: TextStyle(fontSize: 20)),
                    )
                  ],
                )
              ),

              /* "I'm going' / 'I'm not going' notification */
              Container(
                margin: EdgeInsets.only(top: 20),
                child: TextIcon(
                  icon: Icon(Icons.directions_walk, color: (localGoing) ? Colors.green : Colors.grey),
                  text: Text(
                      localGoing ? "I'm going" : "I'm not going",
                    style: TextStyle(
                      color: localGoing ? Colors.green : Colors.grey,
                      fontSize: 20,
                    )
                  ),
                ),
              )
            ],
          ),

          /* Horizontal divider */
          Container(
            margin: EdgeInsets.only(top: 20),
            child: Divider(),
          ),

          /* Description */
          Container(
            width: deviceSize(context).width,
            padding: EdgeInsets.only(top: 10.0, bottom: 50, left: 30, right: 30),
            child: Column(
              children: <Widget>[
                ClickToEditText(clickToEditKey: clickToEditKey, editingDescription: _editingDescription,),
                TextField(
                    controller: _mainTextController,
                    minLines: 1,
                    maxLines: 100,
                    style: TextStyle(fontSize: 13.5),
                    onTap: (){
                      clickToEditKey.currentState.setState(() {clickToEditKey.currentState._editingDescription = true;});
                      editBodyItemKey.currentState.setState(() {editBodyItemKey.currentState._editingDescription = true;});
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
                  editingDescription: _editingDescription,
                  onCancel: (){
                    setState(() {
                      _mainTextController.clear();
                      _mainTextController = TextEditingController(text: widget.event.description);
                      _editingDescription = false;
                    });},
                  onSubmit: (){
                    setState(() {
                      // TODO: change text in server
                      _mainTextController.clear();
                      _mainTextController = TextEditingController(text: widget.event.description);
                      _editingDescription = false;
                    });
                  },
                )
              ],
            ),// TEXT
          ),
        ],
      ),
    );
  }
}

/* Event Image Clipper */
// ignore: camel_case_types
class _mainImageClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();

    path.lineTo(0, size.height);
    path.quadraticBezierTo( size.width / 2,
                            size.height - 70,
                            size.width,
                            size.height);
    path.lineTo(size.width, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class EditPostItem extends StatefulWidget{

  final bool editingDescription;
  final void Function() onSubmit;// TODO:  will be a Future<bool>
  final void Function() onCancel; // TODO:  will be a Future<bool>

  final GlobalKey<_EditPostItemState> editBodyItemKey;

  const EditPostItem({this.editBodyItemKey, this.editingDescription = false, this.onSubmit, this.onCancel}) : super(key: editBodyItemKey);

  @override
  _EditPostItemState createState() => _EditPostItemState();
}

class _EditPostItemState extends State<EditPostItem> {

  bool _editingDescription;

  @override
  void initState() {
    _editingDescription = widget.editingDescription;
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return (_editingDescription ? Padding(
      padding: const EdgeInsets.only(bottom: 300),
      child: Row(
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
      ),
    ): Container());
  }
}

class ClickToEditText extends StatefulWidget{

  final bool editingDescription;
  final GlobalKey<_ClickToEditTextState> clickToEditKey;

  const ClickToEditText({this.clickToEditKey, this.editingDescription}) : super(key: clickToEditKey);


  @override
  _ClickToEditTextState createState() => _ClickToEditTextState();
}

class _ClickToEditTextState extends State<ClickToEditText> {

  bool _editingDescription;

  @override
  void initState() {
    _editingDescription = widget.editingDescription;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _editingDescription ? Container() : Padding(
      padding: EdgeInsets.only(bottom: 5),
      child: Text(_editingDescription ? ' ' : 'Click to edit', style: TextStyle(color: Colors.grey), textAlign: TextAlign.left,),
    );
  }
}

class EditEventComponent{

  // Note: onConfirm returns a Future<bool> so that the validation button can change state when onConfirmed if done.
  static Future<void> show(BuildContext context, {Text title, AEvent event, Widget headerContent, Future<bool> Function() onConfirmed}) async {

    TextEditingController _titleController = TextEditingController(text: event.title);
    TextEditingController _locationController = TextEditingController(text: event.location);
    TextEditingController _placesAvailableController = TextEditingController(text: event.nbrPlaceAvailable.toString());

    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: title,
            content: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  headerContent ?? Container(),
                /* Event title */
                Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(30),
                      child: TextField(
                        textAlign: TextAlign.center,
                        controller: _titleController,
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                    ),

                    /* Event date */
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        Icon(Icons.calendar_today),
                        CustomDatePicker(firstDate: DateTime.now(),lastDate: DateTime.now().add(Duration(days: 365)),),
                        CustomTimePicker(initialTime: event.dateTimeBegin,)
                      ],
                    ),

                    /* Event infos */
                    Container(
                        margin: EdgeInsets.only(top: 25),
                        padding: EdgeInsets.all(5.0),
                        width: deviceSize(context).width * 0.75,

                        /* Row here ! */
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[

                            /* Event Place */
                            Padding(
                              padding: EdgeInsets.all(10),
                              child: TextField(
                                textAlign: TextAlign.center,
                                controller: _locationController,
                              ),
                            ),

                            /* Event number of places available */
                            Padding(
                              padding: EdgeInsets.all(40),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text("Places available : "),
                                  TextField(
                                    textAlign: TextAlign.center,
                                    controller: _placesAvailableController,
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            )
                          ],
                        )
                    ),

                    Center(
                      child: MessageLoadingButton(
                        width: 200,
                        onPressed: () async {

                          //TODO : Update server

                          Timer(Duration(seconds: 1), () {
                            Navigator.of(context).pop(); // Close the AlertDialog
                          });
                          return true;
                        }
                      ),
                    )
                  ],

                ),
              ]
            ),

          ));
        }
    );
  }

}


class CustomTimePicker extends StatefulWidget {
  final DateTime initialTime;

  const CustomTimePicker({Key key, this.initialTime}) : super(key: key);

  @override
  _CustomTimePickerState createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  DateTime time;

  @override
  void initState() {
    super.initState();
    time = widget.initialTime;
  }

  @override
  Widget build(BuildContext context) {
    return FlatButton(
        child: Text(timeToString(time)),
        onPressed: () {
          DatePicker.showTimePicker(

            context,
            showTitleActions: false,
            showSecondsColumn: false,

            onChanged: (date) {
              this.setState(() {
                this.time = date.toLocal();
              });
            },

            currentTime: time,
          );
        }
    );
  }
}

class CustomDatePicker extends StatefulWidget {
  final DateTime  firstDate,
      lastDate;

  const CustomDatePicker({Key key, this.firstDate, this.lastDate}) : super(key: key);

  @override
  _CustomDatePickerState createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  DateTime date;

  @override
  void initState() {
    super.initState();
    date = widget.firstDate;
  }

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      child: Text(DateFormat("dd/MM/yyyy").format(date)),
      onPressed: () async {
        final DateTime picked = await showDatePicker(
          context: context,
          firstDate: widget.firstDate,
          initialDate: widget.firstDate,
          lastDate: widget.lastDate,
        );

        if(picked == null) return;

        this.setState(() {
          date = picked;
        });
      },
    );
  }
}

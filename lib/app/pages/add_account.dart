import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/cache/accounts.dart';

var logger = Logger();

class AddAccountManually extends StatefulWidget {
  @override
  AddAccountManuallyState createState() {
    return AddAccountManuallyState();
  }
}

class AddAccountManuallyState extends State<AddAccountManually> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<AddAccountManuallyState>.
  final _formKey = GlobalKey<FormState>();
  var _accountName = "";
  var _secret = "";
  var currentOtpType = "totp";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Theme.of(context).appBarTheme.color,
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Add account details",
          style: TextStyle(
            color: Theme.of(context).appBarTheme.color,
          ),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        child: Form(
            key: _formKey,
            child: Column(children: <Widget>[
              Container(
                padding: EdgeInsets.all(10),
                child: TextFormField(
                  onChanged: (value) {
                    setState(() {
                      _accountName = value;
                    });
                  },
                  decoration: InputDecoration(
                      border: OutlineInputBorder(), labelText: 'Account name'),
                  // The validator receives the text that the user has entered.
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Too short';
                    }
                    return null;
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.all(10),
                child: TextFormField(
                  onChanged: (value) {
                    setState(() {
                      _secret = value;
                    });
                  },
                  decoration: InputDecoration(
                      border: OutlineInputBorder(), labelText: 'Secret'),
                  // The validator receives the text that the user has entered.
                  validator: (value) {
                    if (value.isEmpty || value.length < 16) {
                      return 'Too short';
                    }
                    return null;
                  },
                ),
              ),
              Container(
                // padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                        flex: 70,
                        child: Container(
                            padding: EdgeInsets.all(10),
                            child: new DropdownButtonFormField(
                              decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Type of key',
                                  hintText: 'Type of key'),
                              value: currentOtpType,
                              icon: Icon(Icons.arrow_downward),
                              items: [
                                {'value': 'totp', 'label': "Time based"},
                                // {'value': 'counter', 'label': "Counter based"},
                              ].map((value) {
                                return new DropdownMenuItem(
                                  value: value["value"],
                                  child: new Text(value["label"]),
                                );
                              }).toList(),
                              onChanged: (value) {
                                currentOtpType = value;
                              },
                            ))),
                    Expanded(
                        flex: 30,
                        child: Container(
                            padding: EdgeInsets.all(10),
                            child: RaisedButton(
                              onPressed: () async {
                                // Validate returns true if the form is valid, otherwise false.
                                if (_formKey.currentState.validate()) {
                                  // If the form is valid, display a snackbar. In the real world,
                                  // you'd often call a server or save the information in a database.
                                  logger.d(
                                      _accountName + _secret + currentOtpType);
                                  await OtpAccount.addAccount(OtpAccount(
                                    accountName: _accountName,
                                    secret: _secret,
                                    otpType: currentOtpType,
                                  ));
                                  final snackBar = SnackBar(
                                    content: Text('Added'),
                                    duration: Duration(milliseconds: 300),
                                  );
                                  Scaffold.of(context).showSnackBar(snackBar);
                                  Navigator.pop(context, true);
                                }
                              },
                              child: Text('Add'),
                            ))),
                  ],
                ),
              ),
            ])),
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add account details"),
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
              RaisedButton(
                onPressed: () async {
                  // Validate returns true if the form is valid, otherwise false.
                  if (_formKey.currentState.validate()) {
                    // If the form is valid, display a snackbar. In the real world,
                    // you'd often call a server or save the information in a database.
                    await OtpAccount.addAccount(
                        OtpAccount(0, _accountName, "000000", "totp"));
                    final snackBar = SnackBar(
                      content: Text('Added'),
                      duration: Duration(milliseconds: 300),
                    );
                    Scaffold.of(context).showSnackBar(snackBar);
                    Navigator.pop(context, true);
                  }
                },
                child: Text('Add'),
              ),
            ])),
      ),
    );
  }
}

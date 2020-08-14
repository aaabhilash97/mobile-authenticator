import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'app/pages/add_account.dart';
import 'app/services/cache/accounts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:authenticator/initialize_i18n.dart' show initializeI18n;
import 'package:authenticator/constants.dart' show languages;
import 'package:authenticator/localizations.dart'
    show MyLocalizations, MyLocalizationsDelegate;
import 'init_link.dart';
import 'package:otp/otp.dart';

var logger = Logger();

class AccountListTile extends StatefulWidget {
  final OtpAccount item;
  final Key key;
  final Function onDelete;

  AccountListTile(
    this.item, {
    this.key,
    this.onDelete,
  });
  @override
  _AccountListTileState createState() => _AccountListTileState();
}

class _AccountListTileState extends State<AccountListTile> {
  bool refreshPage = true;
  var token = "";
  var progress = 0.0;
  Timer timer;

  copToClipBoard(String text, bool isGoBack) {
    Clipboard.setData(new ClipboardData(text: text));

    final snackBar = SnackBar(
      content: Text('Token copied to clipboard'),
      duration: Duration(seconds: 1),
    );
    Scaffold.of(context).showSnackBar(snackBar);
    if (isGoBack) {
      Navigator.pop(context);
    }
  }

  static int timeFormat(DateTime time, int interval) {
    final _timeStr = time.millisecondsSinceEpoch.toString();
    final _formatTime = _timeStr.substring(0, _timeStr.length - 3);

    return int.parse(_formatTime) ~/ interval;
  }

  String generateToken() {
    var _secret = widget.item.secret;
    return OTP.generateTOTPCodeString(
        _secret, new DateTime.now().millisecondsSinceEpoch,
        length: widget.item.getDigits(),
        interval: widget.item.getPeriod(),
        algorithm: widget.item.mapToAlgorithm());
  }

  @override
  void initState() {
    super.initState();

    token = generateToken();

    var counter = new DateTime.now().second;
    progress = ((counter > 30 ? (counter - 30) : counter) / 30) * 100;

    timer = Timer.periodic(new Duration(seconds: 1), (timer) {
      var _newToken = generateToken();

      var counter = new DateTime.now().second;
      var _progress = ((counter > 30 ? (counter - 30) : counter) / 30) * 100;

      setState(() {
        token = _newToken.toString();
        progress = _progress;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
  }

  void deleteItem(OtpAccount item) async {
    await OtpAccount.deleteAccount(item);
    widget.onDelete();
    Navigator.pop(context);
  }

  void _moreAccountActionBottomSheet(context, OtpAccount item) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: new Wrap(
              children: <Widget>[
                new ListTile(
                    leading: new Icon(Icons.content_copy),
                    title: new Text('Copy'),
                    onTap: () => {copToClipBoard(item.token, true)}),
                new ListTile(
                  leading: new Icon(Icons.delete),
                  title: new Text('Delete'),
                  onTap: () => {deleteItem(item)},
                ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 1),
        key: Key(1.toString()),
        title: new GestureDetector(
          child: new Container(
            child: Text(
              widget.item.accountName,
              style: TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
        ),
        subtitle: new GestureDetector(
          onTap: () {
            copToClipBoard(token, false);
          },
          child: new Container(
            child: Text(token,
                style: TextStyle(
                    color: Theme.of(context).textSelectionColor,
                    fontSize: 30,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        leading: Container(
          padding: EdgeInsets.only(left: 10),
          child: new CircularPercentIndicator(
            radius: 40.0,
            lineWidth: 3.0,
            percent: progress / 100,
            center: new Text(
              widget.item.accountName[0].toUpperCase(),
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Theme.of(context).backgroundColor,
            progressColor: Theme.of(context).buttonColor,
          ),
        ),
        trailing: Container(
          child: IconButton(
            icon: Icon(
              Icons.more_vert,
            ),
            onPressed: () {
              _moreAccountActionBottomSheet(context, widget.item);
            },
          ),
        ));
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool refreshPage = true;

  List<OtpAccount> items = [];

  List<int> minAndMax(val1, val2) {
    if (val1 > val2) {
      return [val2, val1];
    }
    return [val1, val2];
  }

  void reorder(oldIndex, newIndex) {
    setState(() {
      var indexes = minAndMax(oldIndex, newIndex);
      var minIndex = indexes[0];
      var maxIndex = indexes[1];
      var part1 = items.sublist(0, minIndex);
      var part2 = items.sublist(minIndex, maxIndex);
      var part3 = items.sublist(maxIndex);

      if (newIndex > oldIndex) {
        var popItem = part2.removeAt(0);
        part2.add(popItem);
      } else {
        part2.add(part3.removeAt(0));
        var popItem = part2.removeAt(part2.length - 1);
        part2.insert(0, popItem);
      }
      List<OtpAccount> newItems = [];
      newItems.addAll(part1);
      newItems.addAll(part2);
      newItems.addAll(part3);

      items = newItems;
    });
  }

  void refresh() {
    setState(() {
      refreshPage = true;
    });
  }

  Future<void> _showInitAccountAddDialog(OtpAccount item) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Save key for'),
          content: Text('${item.accountName}'),
          actions: <Widget>[
            FlatButton(
              child: Text('Save'),
              onPressed: () async {
                await OtpAccount.addAccount(item);
                refresh();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      DeepLinkInitLink _bloc = DeepLinkInitLink();
      _bloc.state.listen((event) async {
        var parsedUri = Uri.parse(event);
        if (parsedUri.scheme == "otpauth") {
          var otpType = parsedUri.host;
          if (otpType == "totp") {
            var accName = parsedUri.path.replaceFirst("/", "");
            var secret = parsedUri.queryParameters["secret"];
            var issuer = parsedUri.queryParameters["issuer"];
            var period = parsedUri.queryParameters["period"];
            var digits = parsedUri.queryParameters["digits"];
            var algorithm = parsedUri.queryParameters["algorithm"];
            await _showInitAccountAddDialog(OtpAccount(
              accountName: accName,
              secret: secret,
              issuer: issuer,
              algorithm: algorithm,
              digits: OtpAccount.defaultDigits(input: digits),
              period: OtpAccount.defaultPeriod(input: period),
            ));
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var fn = "_HomePageState.build";
    logger.d(fn, "Loading home page");
    return Scaffold(
      appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Container(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                MyLocalizations.of(context).title,
                style: TextStyle(
                    fontSize: 25, color: Theme.of(context).appBarTheme.color),
                textAlign: TextAlign.center,
              ),
            ],
          ))),
      body: _buildAccountList(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).buttonColor,
        onPressed: () async {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Scaffold(body: AddAccountManually())),
          ).then((value) => {refresh()});
          // var result = await BarcodeScanner.scan(options: ScanOptions());
          // var parsedUri = Uri.parse(result.rawContent);
          // if (parsedUri.scheme == "otpauth") {
          //   var otpType = parsedUri.host;
          //   if (otpType == "totp") {
          //     print(">>>>>>>>>>>");
          //     print(otpType);
          //     print(parsedUri.path.replaceFirst("/", ""));
          //     print(parsedUri.queryParameters["secret"]);
          //     print(parsedUri.queryParameters["issuer"]);
          //     print(">>>>>>>>>>>");
          //   }
          // }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  copToClipBoard(String text, bool isGoBack) {
    Clipboard.setData(new ClipboardData(text: text));

    final snackBar = SnackBar(
      content: Text('Token copied to clipboard'),
      duration: Duration(seconds: 1),
    );
    Scaffold.of(context).showSnackBar(snackBar);
    if (isGoBack) {
      Navigator.pop(context);
    }
  }

  void loadItems() async {
    var ok = await OtpAccount.accountList();
    setState(() {
      items = ok;
      refreshPage = false;
    });
  }

  Widget _buildAccountList() {
    if (refreshPage) {
      loadItems();
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    return new ReorderableListView(
      onReorder: (oldIndex, newIndex) {
        reorder(oldIndex, newIndex);
      },
      scrollDirection: Axis.vertical,
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      children: [
        for (final item in items)
          AccountListTile(
            item,
            key: Key(item.index.toString()),
            onDelete: () => {
              refresh(),
            },
          ),
      ],
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Map<String, Map<String, String>> localizedValues = await initializeI18n();
  runApp(App(localizedValues));
}

class App extends StatefulWidget {
  final Map<String, Map<String, String>> localizedValues;
  App(this.localizedValues);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  String _locale = 'en';
  onChangeLanguage() {
    if (_locale == 'en') {
      setState(() {
        _locale = 'ml';
      });
    } else {
      setState(() {
        _locale = 'en';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var darkTheme = ThemeData.dark().copyWith(
        appBarTheme: AppBarTheme(
          color: Colors.grey,
        ),
        accentColor: Colors.blue,
        // splashColor: Colors.blue,
        textSelectionColor: Colors.blue,
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.white,
            ));
    return new MaterialApp(
        themeMode: ThemeMode.system,
        theme: ThemeData(
          appBarTheme: AppBarTheme(
            color: Colors.grey[600],
          ),
          buttonColor: Colors.blue,
          backgroundColor: Colors.grey,
          accentColor: Colors.blue,
          splashColor: Colors.blue,
          textSelectionColor: Colors.blue,
        ),
        darkTheme: darkTheme,
        locale: Locale(_locale),
        localizationsDelegates: [
          MyLocalizationsDelegate(widget.localizedValues),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: languages.map((language) => Locale(language, '')),
        home: HomePage());
  }
}

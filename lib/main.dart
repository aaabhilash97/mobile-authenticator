import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'app/services/cache/accounts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:authenticator/app/pages/add_account.dart';
import 'package:authenticator/initialize_i18n.dart' show initializeI18n;
import 'package:authenticator/constants.dart' show languages;
import 'package:authenticator/localizations.dart'
    show MyLocalizations, MyLocalizationsDelegate;
import 'init_link.dart';
import 'package:otp/otp.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter_camera_ml_vision/flutter_camera_ml_vision.dart';

// import 'package:qr_mobile_vision/qr_camera.dart';

var logger = Logger();

class ScanPage extends StatefulWidget {
  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool resultSent = false;
  BarcodeDetector detector = FirebaseVision.instance.barcodeDetector();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          height: MediaQuery.of(context).size.width,
          width: MediaQuery.of(context).size.width,
          child: CameraMlVision<List<Barcode>>(
            overlayBuilder: (c) {
              return Container(
                decoration: ShapeDecoration(
                  shape: _ScannerOverlayShape(
                    borderColor: Theme.of(context).primaryColor,
                    borderWidth: 3.0,
                  ),
                ),
              );
            },
            detector: detector.detectInImage,
            onResult: (List<Barcode> barcodes) {
              if (!mounted ||
                  resultSent ||
                  barcodes == null ||
                  barcodes.isEmpty) {
                return;
              }
              if (barcodes.first.rawValue.startsWith("otpauth")) {
                resultSent = true;
                logger.w(barcodes.first.rawValue);
                Navigator.pop(context, barcodes.first.rawValue);
              }
            },
            onDispose: () {
              detector.close();
            },
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;

  _ScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 1.0,
    this.overlayColor = const Color(0x88000000),
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect)
      ..lineTo(
        rect.right,
        rect.bottom,
      )
      ..lineTo(
        rect.left,
        rect.bottom,
      )
      ..lineTo(
        rect.left,
        rect.top,
      );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection textDirection}) {
    const lineSize = 30;

    final width = rect.width;
    final borderWidthSize = width * 10 / 100;
    final height = rect.height;
    final borderHeightSize = height - (width - borderWidthSize);
    final borderSize = Size(borderWidthSize / 2, borderHeightSize / 2);

    var paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas
      ..drawRect(
        Rect.fromLTRB(
            rect.left, rect.top, rect.right, borderSize.height + rect.top),
        paint,
      )
      ..drawRect(
        Rect.fromLTRB(rect.left, rect.bottom - borderSize.height, rect.right,
            rect.bottom),
        paint,
      )
      ..drawRect(
        Rect.fromLTRB(rect.left, rect.top + borderSize.height,
            rect.left + borderSize.width, rect.bottom - borderSize.height),
        paint,
      )
      ..drawRect(
        Rect.fromLTRB(
            rect.right - borderSize.width,
            rect.top + borderSize.height,
            rect.right,
            rect.bottom - borderSize.height),
        paint,
      );

    paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final borderOffset = borderWidth / 2;
    final realReact = Rect.fromLTRB(
        borderSize.width + borderOffset,
        borderSize.height + borderOffset + rect.top,
        width - borderSize.width - borderOffset,
        height - borderSize.height - borderOffset + rect.top);

    //Draw top right corner
    canvas
      ..drawPath(
          Path()
            ..moveTo(realReact.right, realReact.top)
            ..lineTo(realReact.right, realReact.top + lineSize),
          paint)
      ..drawPath(
          Path()
            ..moveTo(realReact.right, realReact.top)
            ..lineTo(realReact.right - lineSize, realReact.top),
          paint)
      ..drawPoints(
        PointMode.points,
        [Offset(realReact.right, realReact.top)],
        paint,
      )

      //Draw top left corner
      ..drawPath(
          Path()
            ..moveTo(realReact.left, realReact.top)
            ..lineTo(realReact.left, realReact.top + lineSize),
          paint)
      ..drawPath(
          Path()
            ..moveTo(realReact.left, realReact.top)
            ..lineTo(realReact.left + lineSize, realReact.top),
          paint)
      ..drawPoints(
        PointMode.points,
        [Offset(realReact.left, realReact.top)],
        paint,
      )

      //Draw bottom right corner
      ..drawPath(
          Path()
            ..moveTo(realReact.right, realReact.bottom)
            ..lineTo(realReact.right, realReact.bottom - lineSize),
          paint)
      ..drawPath(
          Path()
            ..moveTo(realReact.right, realReact.bottom)
            ..lineTo(realReact.right - lineSize, realReact.bottom),
          paint)
      ..drawPoints(
        PointMode.points,
        [Offset(realReact.right, realReact.bottom)],
        paint,
      )

      //Draw bottom left corner
      ..drawPath(
          Path()
            ..moveTo(realReact.left, realReact.bottom)
            ..lineTo(realReact.left, realReact.bottom - lineSize),
          paint)
      ..drawPath(
          Path()
            ..moveTo(realReact.left, realReact.bottom)
            ..lineTo(realReact.left + lineSize, realReact.bottom),
          paint)
      ..drawPoints(
        PointMode.points,
        [Offset(realReact.left, realReact.bottom)],
        paint,
      );
  }

  @override
  ShapeBorder scale(double t) {
    return _ScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}

class AccountListTile extends StatefulWidget {
  final OtpAccount item;
  final Key key;
  final Function onDelete;
  final Function onNewAccount;

  AccountListTile(
    this.item, {
    this.key,
    this.onDelete,
    this.onNewAccount,
  });
  @override
  _AccountListTileState createState() => _AccountListTileState();
}

class OtpToken {
  Widget view;
  double progress;
  bool isSuccess;

  OtpToken({this.view, this.progress, this.isSuccess = false});

  static OtpToken generateToken({
    OtpAccount item,
    Function(String, bool) onTap,
    Color textColor,
    Color errorColor,
  }) {
    var _secret = item.secret;
    var counter = new DateTime.now().second;
    var _progress = ((counter > 30 ? (counter - 30) : counter) / 30) * 100;
    try {
      var token = OTP.generateTOTPCodeString(
          _secret, new DateTime.now().millisecondsSinceEpoch,
          length: item.getDigits(),
          interval: item.getPeriod(),
          algorithm: item.mapToAlgorithm());
      return OtpToken(
        isSuccess: true,
        progress: _progress,
        view: new GestureDetector(
          onTap: () => {
            onTap(token, false),
          },
          child: new Container(
            child: Text(token,
                style: TextStyle(
                    color: textColor,
                    fontSize: 30,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      );
    } catch (e) {
      return OtpToken(
        progress: 0,
        view: Text("Invalid Otp secret",
            style: TextStyle(
                color: errorColor,
                fontSize: 10,
                fontWeight: FontWeight.normal)),
      );
    }
  }
}

class _AccountListTileState extends State<AccountListTile> {
  bool refreshPage = true;
  Widget token;
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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var otpToken = OtpToken.generateToken(
          item: widget.item,
          onTap: copToClipBoard,
          textColor: Theme.of(context).textSelectionColor,
          errorColor: Theme.of(context).errorColor);
      setState(() {
        token = otpToken.view;
        progress = otpToken.progress;
      });
      if (otpToken.isSuccess) {
        timer = Timer.periodic(new Duration(seconds: 1), (timer) {
          otpToken = OtpToken.generateToken(
              item: widget.item,
              onTap: copToClipBoard,
              textColor: Theme.of(context).textSelectionColor,
              errorColor: Theme.of(context).errorColor);

          setState(() {
            token = otpToken.view;
            progress = otpToken.progress;
          });
        });
      }
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
        subtitle: token,
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

class QrCodeScanner extends StatefulWidget {
  @override
  _QrCodeScannerState createState() => new _QrCodeScannerState();
}

class _QrCodeScannerState extends State<QrCodeScanner> {
  var camState = true;
  String qrCode = "";
  @override
  Widget build(BuildContext context) {
    if (!camState) {
      Navigator.pop(context, qrCode);
    }
    return camState
        ? new Scaffold(
            appBar: new AppBar(
              title: new Text('Scan Qrcode'),
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
            body: new Center(
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new Expanded(
                      child: new Center(
                    child: new SizedBox(
                      width: 300.0,
                      height: 300.0,
                      // child: new QrCamera(
                      //   onError: (context, error) => Text(
                      //     error.toString(),
                      //     style: TextStyle(color: Colors.red),
                      //   ),
                      //   qrCodeCallback: (code) {
                      //     setState(() {
                      //       camState = false;
                      //       qrCode = code;
                      //     });
                      //   },
                      //   child: new Container(
                      //     decoration: new BoxDecoration(
                      //       color: Colors.transparent,
                      //       border: Border.all(
                      //           color: Colors.orange,
                      //           width: 1.0,
                      //           style: BorderStyle.solid),
                      //     ),
                      //   ),
                      // ),
                    ),
                  )),
                ],
              ),
            ),
          )
        : new Center(child: new Text("Camera inactive"));
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

  Future<void> openQrcodeScan() async {
    var qrCode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Scaffold(body: ScanPage())),
    );
    logger.w(qrCode);
    await parseAndAddAccount(qrCode);
    Navigator.of(context).pop();
  }

  Future<void> openAddAccountManually() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Scaffold(body: AddAccountManually())),
    );
    refresh();
    Navigator.of(context).pop();
  }

  void _addAccountButtonActionBottomSheet(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: new Wrap(
              children: <Widget>[
                new ListTile(
                    leading: new Icon(Icons.keyboard),
                    title: new Text('Add acount manually'),
                    onTap: () => {
                          openAddAccountManually(),
                        }),
                new ListTile(
                  leading: new Icon(Icons.camera),
                  title: new Text('Scan Qrcode'),
                  onTap: () => {
                    openQrcodeScan(),
                  },
                ),
              ],
            ),
          );
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
      _bloc.state.listen((qrCode) async {
        await parseAndAddAccount(qrCode);
      });
    });
  }

  Future<void> parseAndAddAccount(String qrCode) async {
    var parsedUri = Uri.parse(qrCode);
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
          _addAccountButtonActionBottomSheet(context);
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
            onNewAccount: (OtpAccount item) => {
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

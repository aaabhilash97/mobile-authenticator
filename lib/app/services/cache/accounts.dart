// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

var logger = Logger();

class OtpAccount {
  int index;
  final String accountName;
  final String secret;
  final String otpType;

  OtpAccount(this.index, this.accountName, this.secret, this.otpType);

  OtpAccount.fromJson(Map<String, dynamic> json)
      : index = json['index'],
        accountName = json['account_name'],
        secret = json['secret'],
        otpType = json['otp_type'];

  Map<String, dynamic> toJson() => {
        'index': index,
        'account_name': accountName,
        'secret': secret,
        'otp_type': otpType,
      };

  static Future<List<OtpAccount>> accountList() async {
    List<OtpAccount> accounts = [];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var savedAccounts = prefs.getString("accounts");
    if (savedAccounts == null || savedAccounts.isEmpty) {
      return accounts;
    } else {
      var accountsMap = jsonDecode(savedAccounts) as List;
      accountsMap.forEach((e) {
        accounts.add(OtpAccount.fromJson(e));
      });
      return accounts;
    }
  }

  static addAccount(OtpAccount item) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var accounts = await accountList();
    item.index = accounts.length;
    accounts.add(item);
    await prefs.setString("accounts", jsonEncode(accounts));
  }
}

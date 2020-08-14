// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'package:otp/otp.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

var logger = Logger();

class OtpAccount {
  String id;
  int index;
  final String accountName;
  final String secret;
  final String otpType;
  final String issuer;
  final String algorithm;
  final int digits;
  final int period;

  String token;

  OtpAccount({
    this.accountName,
    this.secret,
    this.otpType = "totp",
    this.issuer,
    this.algorithm = "SHA1",
    this.digits = 6,
    this.period = 30,
  });

  OtpAccount.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        index = json['index'],
        accountName = json['account_name'],
        secret = json['secret'],
        otpType = json['otp_type'],
        issuer = json['issuer'],
        algorithm = json['algorithm'],
        digits = json['digits'],
        period = json['period'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'index': index,
        'account_name': accountName,
        'secret': secret,
        'otp_type': otpType,
        'issuer': issuer,
        'algorithm': algorithm,
        'digits': digits,
        'period': period,
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

    var uuid = Uuid();
    item.id = uuid.v4();
    item.index = accounts.length;
    accounts.add(item);

    await prefs.setString("accounts", jsonEncode(accounts));
  }

  static deleteAccount(OtpAccount item) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var accounts = await accountList();
    for (var i = 0; i < accounts.length; i++) {
      if (accounts[i].id == item.id) {
        accounts.removeAt(i);
      }
    }
    await prefs.setString("accounts", jsonEncode(accounts));
  }

  int getPeriod() {
    try {
      if (this.period > 0) {
        return this.period;
      }
    } catch (e) {
      logger.e("getPeriod.parse", e);
    }
    return 30;
  }

  int getDigits() {
    try {
      if (this.digits > 0) {
        return this.digits;
      }
    } catch (e) {
      logger.e("getDigits.parse", e);
    }
    return 6;
  }

  static int defaultPeriod({String input = ""}) {
    try {
      if (input.isNotEmpty) {
        return int.parse(input);
      }
    } catch (e) {
      logger.e("defaultPeriod.parse", e);
    }
    return 30;
  }

  static int defaultDigits({String input = ""}) {
    try {
      if (input.isNotEmpty) {
        return int.parse(input);
      }
    } catch (e) {
      logger.e("defaultDigits.parse", e);
    }
    return 6;
  }

  Algorithm mapToAlgorithm() {
    try {
      var _algorithm = this.algorithm;
      if (_algorithm != null && _algorithm.length > 1) {
        _algorithm = _algorithm.toUpperCase();
        if (_algorithm == "SHA1") {
          return Algorithm.SHA1;
        } else if (_algorithm == "SHA256") {
          return Algorithm.SHA256;
        } else if (_algorithm == "SHA512") {
          return Algorithm.SHA512;
        }
      }
    } catch (e) {
      logger.e("mapToAlgorithm.parse", e);
    }
    return Algorithm.SHA1;
  }
}

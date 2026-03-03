import 'dart:async';
import 'package:flutter/material.dart';

class SessionService {
  Timer? _inactivityTimer;
  final int _timeoutInMinutes;
  VoidCallback? onTimeout;

  SessionService(this._timeoutInMinutes);

  void startTimer() {
    resetTimer();
  }

  void resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(Duration(minutes: _timeoutInMinutes), () {
      if (onTimeout != null) {
        onTimeout!();
      }
    });
  }

  void stopTimer() {
    _inactivityTimer?.cancel();
  }
}

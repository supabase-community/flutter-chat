import 'dart:async';

import 'package:rxdart/subjects.dart';
import 'package:supabase_quickstart/models/message.dart';
import 'package:supabase_quickstart/models/room.dart';
import 'package:supabase_quickstart/utils/constants.dart';

/// Data store to store in memory app data
/// without any state management packages
class Store {
  static final Store _singleton = Store._internal();

  factory Store() {
    return _singleton;
  }

  Store._internal();
}

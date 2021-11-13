/// Data store to store in memory app data
/// without any state management packages
class Store {
  static final Store _singleton = Store._internal();

  factory Store() {
    return _singleton;
  }

  Store._internal();
}

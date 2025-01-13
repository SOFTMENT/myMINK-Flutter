class Result<T> {
  final T? data;
  final String? error;

  Result({this.data, this.error});

  // Helper method to check if the result contains data
  bool get hasData => data != null;

  // Helper method to check if there's an error
  bool get hasError => error != null;
}

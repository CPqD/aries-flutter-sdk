class RevocationNotification {
  final String? comment;
  final DateTime? revocationDate;

  RevocationNotification({
    this.comment,
    this.revocationDate,
  });

  factory RevocationNotification.fromMap(Map<String, dynamic> map) {
    return RevocationNotification(
      comment: map["comment"].toString(),
      revocationDate: DateTime.tryParse(map["revocationDate"].toString()),
    );
  }

  @override
  String toString() {
    return 'RevocationNotification{'
        'comment: $comment, '
        'revocationDate: $revocationDate'
        '}';
  }
}

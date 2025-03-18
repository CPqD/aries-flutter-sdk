class CredentialExchangeRecord {
  final String id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String connectionId;
  final String threadId;
  final String state;
  final String protocolVersion;

  CredentialExchangeRecord({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.connectionId,
    required this.threadId,
    required this.state,
    required this.protocolVersion,
  });

  factory CredentialExchangeRecord.fromMap(Map<String, dynamic> map) {
    return CredentialExchangeRecord(
      id: map["id"].toString(),
      createdAt: DateTime.tryParse(map["createdAt"].toString()),
      updatedAt: DateTime.tryParse(map["updatedAt"].toString()),
      connectionId: map["connectionId"].toString(),
      threadId: map["threadId"].toString(),
      state: map["state"].toString(),
      protocolVersion: map["protocolVersion"].toString(),
    );
  }

  @override
  String toString() {
    return 'CredentialExchangeRecord{'
        'id: $id, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt, '
        'connectionId: $connectionId, '
        'connectionId: $threadId, '
        'state: $state, '
        'protocolVersion: $protocolVersion'
        '}';
  }
}

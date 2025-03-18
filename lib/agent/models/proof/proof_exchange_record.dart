class ProofExchangeRecord {
  final String id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String connectionId;
  final String threadId;
  final String state;

  ProofExchangeRecord({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.connectionId,
    required this.threadId,
    required this.state,
  });

  factory ProofExchangeRecord.fromMap(Map<String, dynamic> map) {
    return ProofExchangeRecord(
      id: map["id"].toString(),
      createdAt: DateTime.tryParse(map["createdAt"].toString()),
      updatedAt: DateTime.tryParse(map["updatedAt"].toString()),
      connectionId: map["connectionId"].toString(),
      threadId: map["threadId"].toString(),
      state: map["state"].toString(),
    );
  }

  @override
  String toString() {
    return 'ProofExchangeRecord{'
        'id: $id, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt, '
        'connectionId: $connectionId, '
        'connectionId: $threadId, '
        'state: $state'
        '}';
  }
}

class ConnectionInvitationMessage {
  final String id;
  final String label;
  final String? imageUrl;
  final String? did;
  final List<String>? recipientKeys;
  final String? serviceEndpoint;
  final List<String>? routingKeys;

  ConnectionInvitationMessage({
    required this.id,
    required this.label,
    this.imageUrl,
    this.did,
    this.recipientKeys,
    this.serviceEndpoint,
    this.routingKeys,
  });

  factory ConnectionInvitationMessage.fromMap(Map<String, dynamic> map) {
    return ConnectionInvitationMessage(
      id: map['id'],
      label: map['label'],
      imageUrl: map['imageUrl'],
      did: map['did'],
      recipientKeys: List<String>.from(map['recipientKeys'] ?? []),
      serviceEndpoint: map['serviceEndpoint'],
      routingKeys: List<String>.from(map['routingKeys'] ?? []),
    );
  }

  @override
  String toString() {
    return 'ConnectionInvitationMessage{'
        'id: $id, '
        'label: $label, '
        'did: $did, '
        'recipientKeys: $recipientKeys, '
        'serviceEndpoint: $serviceEndpoint, '
        'routingKeys: $routingKeys'
        '}';
  }
}

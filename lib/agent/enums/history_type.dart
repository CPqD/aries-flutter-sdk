enum HistoryType {
  basicMessageReceived('BasicMessageReceived'),
  basicMessageSent('BasicMessageSent'),
  connectionCreated('ConnectionCreated'),
  credentialOfferAccepted('CredentialOfferAccepted'),
  credentialOfferDeclined('CredentialOfferDeclined'),
  credentialOfferReceived('CredentialOfferReceived'),
  credentialRevoked('CredentialRevoked'),
  proofRequestAccepted('ProofRequestAccepted'),
  proofRequestDeclined('ProofRequestDeclined'),
  proofRequestReceived('ProofRequestReceived');

  final String value;

  const HistoryType(this.value);

  bool equals(String otherValue) => value == otherValue;

  static bool isSent(String value) {
    final sentStates = {
      connectionCreated,
      credentialOfferAccepted,
      credentialOfferDeclined,
      proofRequestAccepted,
      proofRequestDeclined
    };
    return sentStates.any((state) => state.value == value);
  }

  static bool isFromCredentialOffer(String value) {
    final credOfferStates = {
      credentialOfferAccepted,
      credentialOfferDeclined,
      credentialOfferReceived
    };
    return credOfferStates.any((state) => state.value == value);
  }

  static bool isFromProof(String value) {
    final proofStates = {
      proofRequestAccepted,
      proofRequestDeclined,
      proofRequestReceived
    };
    return proofStates.any((state) => state.value == value);
  }

  factory HistoryType.from(String value) {
    return HistoryType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Invalid HistoryType: $value'),
    );
  }
}

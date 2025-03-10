import 'package:did_agent/agent/enums/connection.dart';

class ConnectionRecord {
  final String id;
  final ConnectionState state;
  final ConnectionRole role;
  final String did;
  // final DidDoc didDoc;
  final String verkey;
  // final DidDoc? theirDidDoc;
  final String? theirDid;
  final String? theirLabel;
  // final ConnectionInvitationMessage? invitation;
  final String? alias;
  final bool? autoAcceptConnection;
  final String? imageUrl;
  final bool multiUseInvitation;
  // final OutOfBandInvitation? outOfBandInvitation;
  final String? threadId;
  final String? mediatorId;
  final String? errorMessage;

  ConnectionRecord({
    required this.id,
    required this.state,
    required this.role,
    required this.did,
    required this.verkey,
    this.theirDid,
    this.theirLabel,
    this.alias,
    this.autoAcceptConnection,
    this.imageUrl,
    required this.multiUseInvitation,
    this.threadId,
    this.mediatorId,
    this.errorMessage,
  });

  factory ConnectionRecord.fromMap(Map<String, dynamic> map) {
    return ConnectionRecord(
      id: map["id"].toString(),
      state: ConnectionState.from(map["state"].toString()),
      role: ConnectionRole.from(map["role"].toString()),
      did: map["did"].toString(),
      verkey: map["verkey"].toString(),
      theirDid: map["theirDid"].toString(),
      theirLabel: map["theirLabel"].toString(),
      alias: map["alias"].toString(),
      autoAcceptConnection: map["autoAcceptConnection"].toString().toLowerCase() == 'true',
      imageUrl: map["imageUrl"].toString(),
      multiUseInvitation: map["multiUseInvitation"].toString().toLowerCase() == 'true',
      threadId: map["threadId"].toString(),
      mediatorId: map["mediatorId"].toString(),
      errorMessage: map["errorMessage"].toString(),
    );
  }

    @override
  String toString() {
    return 'ConnectionRecord{'
        'id: $id, '
        'state: $state, '
        'role: $role, '
        'alias: $alias, '
        'did: $did, '
        'verkey: $verkey, '
        'theirDid: $theirDid, '
        'theirLabel: $theirLabel, '
        'autoAcceptConnection: $autoAcceptConnection, '
        'imageUrl: $imageUrl, '
        'multiUseInvitation: $multiUseInvitation, '
        'threadId: $threadId, '
        'mediatorId: $mediatorId, '
        'errorMessage: $errorMessage'
        '}';
  }
}

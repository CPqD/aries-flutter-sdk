import 'package:did_agent/agent/enums/connection.dart';
import 'package:did_agent/agent/models/connection_invitation_message.dart';
import 'package:did_agent/agent/models/did_doc.dart';

class ConnectionRecord {
  final String id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ConnectionState state;
  final ConnectionRole role;
  final String did;
  final DidDoc didDoc;
  final String verkey;
  final DidDoc? theirDidDoc;
  final String? theirDid;
  final String? theirLabel;
  final ConnectionInvitationMessage? invitation;
  final String? alias;
  final bool autoAcceptConnection;
  final String? imageUrl;
  final bool multiUseInvitation;
  final Map<String, dynamic>? outOfBandInvitation;
  final String? threadId;
  final String? mediatorId;
  final String? errorMessage;

  ConnectionRecord({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.state,
    required this.role,
    required this.did,
    required this.didDoc,
    required this.verkey,
    this.theirDidDoc,
    this.theirDid,
    this.theirLabel,
    this.invitation,
    this.alias,
    this.autoAcceptConnection = false,
    this.imageUrl,
    required this.multiUseInvitation,
    this.outOfBandInvitation,
    this.threadId,
    this.mediatorId,
    this.errorMessage,
  });

  factory ConnectionRecord.fromMap(Map<String, dynamic> map) {
    print('invitation: ${map['invitation']}');

    return ConnectionRecord(
      id: map["id"].toString(),
      createdAt: DateTime.tryParse(map["createdAt"].toString()),
      updatedAt: DateTime.tryParse(map["updatedAt"].toString()),
      state: ConnectionState.from(map["state"].toString()),
      role: ConnectionRole.from(map["role"].toString()),
      did: map["did"].toString(),
      didDoc: DidDoc.fromMap(map["didDoc"]),
      verkey: map["verkey"].toString(),
      theirDidDoc: DidDoc.fromMap(map["theirDidDoc"]),
      theirDid: map["theirDid"].toString(),
      theirLabel: map["theirLabel"].toString(),
      invitation: map["invitation"] == null
          ? null
          : ConnectionInvitationMessage.fromMap(map["invitation"]),
      outOfBandInvitation: map["outOfBandInvitation"],
      alias: map["alias"].toString(),
      autoAcceptConnection:
          map["autoAcceptConnection"].toString().toLowerCase() == 'true',
      imageUrl: map["imageUrl"].toString(),
      multiUseInvitation: map["multiUseInvitation"].toString().toLowerCase() == 'true',
      threadId: map["threadId"].toString(),
      mediatorId: map["mediatorId"].toString(),
      errorMessage: map["errorMessage"].toString(),
    );
  }

  String getName() {
    return theirLabel ?? 'Conexão';
  }

  @override
  String toString() {
    return 'ConnectionRecord{'
        'id: $id, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt, '
        'state: $state, '
        'role: $role, '
        'did: $did, '
        'didDoc: $didDoc, '
        'verkey: $verkey, '
        'theirDidDoc: $theirDidDoc, '
        'theirDid: $theirDid, '
        'theirLabel: $theirLabel, '
        'invitation: $invitation, '
        'outOfBandInvitation: $outOfBandInvitation, '
        'alias: $alias, '
        'autoAcceptConnection: $autoAcceptConnection, '
        'imageUrl: $imageUrl, '
        'multiUseInvitation: $multiUseInvitation, '
        'threadId: $threadId, '
        'mediatorId: $mediatorId, '
        'errorMessage: $errorMessage'
        '}';
  }
}

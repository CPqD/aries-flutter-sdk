import 'package:did_agent/agent/aries_result.dart';
import 'package:did_agent/util/utils.dart';
import 'package:flutter/material.dart';

class InvitationPage extends StatefulWidget {
  const InvitationPage({super.key});

  @override
  State<InvitationPage> createState() => _InvitationPageState();
}

class _InvitationPageState extends State<InvitationPage> {
  Future<AriesResult<String>>? _invitationUrlFuture;

  @override
  void initState() {
    super.initState();
    _invitationUrlFuture = generateInvitation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gerar Convite'),
      ),
      body: FutureBuilder<AriesResult<String>>(
        future: _invitationUrlFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return Center(
              child: SelectableText(
                  snapshot.data?.value ?? 'Não foi possível gerar o convite.'),
            );
          } else {
            return Center(child: Text('No connections found.'));
          }
        },
      ),
    );
  }
}

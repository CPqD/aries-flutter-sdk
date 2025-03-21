import 'package:did_agent/agent/aries_result.dart';
import 'package:did_agent/agent/models/connection/connection_record.dart';
import 'package:did_agent/page/connection_details_page.dart';
import 'package:did_agent/util/utils.dart';
import 'package:flutter/material.dart';

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key});

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  Future<AriesResult<List<ConnectionRecord>>>? _connectionsFuture;

  @override
  void initState() {
    super.initState();
    _connectionsFuture = getConnections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conexões'),
      ),
      body: FutureBuilder<AriesResult<List<ConnectionRecord>>>(
        future: _connectionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.success == false) {
            return Center(child: Text('Erro: ${snapshot.error ?? snapshot.data?.error}'));
          }

          if (snapshot.data!.value!.isEmpty) {
            return Center(child: Text('Nenhuma conexão encontrada.'));
          }

          final connections = snapshot.data!.value as List<ConnectionRecord>;

          return ListView.builder(
            itemCount: connections.length,
            itemBuilder: (context, index) {
              final connection = connections[index];

              print('connection: $connection');

              return ListTile(
                  title: Text(connection.id),
                  subtitle: Text(
                      '${connection.theirLabel}\n${connection.state.value}\n${connection.createdAt?.toLocal()}'),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ConnectionDetailsPage(connection: connection),
                      ),
                    );

                    if (result == true) {
                      setState(() {
                        _connectionsFuture = getConnections();
                      });
                    }
                  });
            },
          );
        },
      ),
    );
  }
}

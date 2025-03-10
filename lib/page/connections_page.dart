import 'package:did_agent/agent/aries_result.dart';
import 'package:did_agent/agent/models/connection_record.dart';
import 'package:flutter/material.dart';
import 'package:did_agent/util/utils.dart';

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key});

  @override
  _ConnectionsPageState createState() => _ConnectionsPageState();
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
        title: Text('Connections Page'),
      ),
      body: FutureBuilder<AriesResult<List<ConnectionRecord>>>(
        future: _connectionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.success == false) {
            return Center(
                child: Text('Error: ${snapshot.error ?? snapshot.data?.error}'));
          }

          if (snapshot.data!.value!.isEmpty) {
            return Center(child: Text('No connections found.'));
          }

          final connections = snapshot.data!.value as List<ConnectionRecord>;

          return ListView.builder(
            itemCount: connections.length,
            itemBuilder: (context, index) {
              final connection = connections[index];

              return ListTile(
                title: Text(connection.id),
                subtitle: Text('${connection.theirLabel}\n${connection.state.value}'),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

void main() => runApp(const SSHClientApp());
class SSHClientApp extends StatelessWidget {
  const SSHClientApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(title: 'SSH终端客户端', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.blueGrey, useMaterial3: true, brightness: Brightness.dark),
    home: const SSHHomePage());
}

class SSHConnection {
  final String name, host, username, port;
  bool connected;
  SSHConnection({required this.name, required this.host, required this.username, this.port = '22', this.connected = false});
}

class TerminalLine {
  final String text;
  final bool isCommand;
  TerminalLine(this.text, {this.isCommand = false});
}

class SSHHomePage extends StatefulWidget {
  const SSHHomePage({super.key});
  @override
  State<SSHHomePage> createState() => _SSHHomePageState();
}

class _SSHHomePageState extends State<SSHHomePage> {
  List<SSHConnection> _connections = [
    SSHConnection(name: '生产服务器', host: '192.168.1.100', username: 'root'),
    SSHConnection(name: '测试服务器', host: '10.0.0.50', username: 'dev'),
  ];
  SSHConnection? _active;
  List<TerminalLine> _output = [];
  final _cmdCtrl = TextEditingController();

  void _connect(SSHConnection conn) {
    setState(() {
      _active = conn;
      conn.connected = true;
      _output = [
        TerminalLine('Connecting to ${conn.host}...'),
        TerminalLine('Welcome to Ubuntu 22.04 LTS'),
        TerminalLine('Last login: ${DateTime.now()}'),
        TerminalLine(''),
      ];
    });
  }

  void _execCommand() {
    if (_cmdCtrl.text.isEmpty) return;
    final cmd = _cmdCtrl.text;
    setState(() {
      _output.add(TerminalLine('${_active!.username}@${_active!.host}:~\$ $cmd', isCommand: true));
      if (cmd == 'ls') {
        _output.addAll([TerminalLine('Documents  Downloads  Music  Pictures  Projects'), TerminalLine('')]);
      } else if (cmd == 'pwd') {
        _output.addAll([TerminalLine('/home/${_active!.username}'), TerminalLine('')]);
      } else if (cmd == 'whoami') {
        _output.addAll([TerminalLine(_active!.username), TerminalLine('')]);
      } else if (cmd == 'date') {
        _output.addAll([TerminalLine(DateTime.now().toString()), TerminalLine('')]);
      } else if (cmd == 'clear') {
        _output.clear();
      } else if (cmd.startsWith('echo ')) {
        _output.addAll([TerminalLine(cmd.substring(5)), TerminalLine('')]);
      } else {
        _output.addAll([TerminalLine('bash: $cmd: command not found'), TerminalLine('')]);
      }
    });
    _cmdCtrl.clear();
  }

  void _addConnection() {
    final nameC = TextEditingController(), hostC = TextEditingController(), userC = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('添加SSH连接'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, decoration: const InputDecoration(labelText: '名称', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: hostC, decoration: const InputDecoration(labelText: '主机', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: userC, decoration: const InputDecoration(labelText: '用户名', border: OutlineInputBorder())),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')), FilledButton(onPressed: () { if (nameC.text.isNotEmpty) setState(() => _connections.add(SSHConnection(name: nameC.text, host: hostC.text, username: userC.text))); Navigator.pop(ctx); }, child: const Text('添加'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('💻 SSH终端'), centerTitle: true, actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: _addConnection),
      ]),
      body: Column(children: [
        // 连接栏
        SizedBox(height: 72, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(12), itemCount: _connections.length, itemBuilder: (ctx, i) {
          final c = _connections[i];
          final isActive = _active?.host == c.host;
          return GestureDetector(onTap: () => _connect(c), child: Container(width: 130, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(color: isActive ? Colors.blueGrey : Colors.grey.shade800, borderRadius: BorderRadius.circular(12)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.terminal, color: isActive ? Colors.white : Colors.grey),
            Text(c.name, style: TextStyle(color: isActive ? Colors.white : null, fontWeight: FontWeight.bold, fontSize: 12)),
            Text('${c.username}@${c.host}', style: TextStyle(color: isActive ? Colors.white70 : Colors.grey, fontSize: 9)),
          ])));
        })),
        // 终端输出
        Expanded(child: Container(color: Colors.black, padding: const EdgeInsets.all(8), child: _active == null ? Center(child: Text('选择服务器连接', style: TextStyle(color: Colors.grey.shade600))) : ListView.builder(controller: ScrollController(), itemCount: _output.length, itemBuilder: (ctx, i) {
          final line = _output[i];
          return Text(line.text, style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: line.isCommand ? Colors.green : Colors.white70));
        }))),
        // 命令输入
        if (_active != null) Container(padding: const EdgeInsets.all(8), color: Colors.grey.shade900, child: Row(children: [
          Text('${_active!.username}@host:\~\$', style: const TextStyle(fontFamily: 'monospace', color: Colors.green, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _cmdCtrl, style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 13), decoration: const InputDecoration(border: InputBorder.none, isDense: true), onSubmitted: (_) => _execCommand())),
          IconButton(icon: const Icon(Icons.send, color: Colors.green, size: 20), onPressed: _execCommand),
        ])),
      ]),
    );
  }
}

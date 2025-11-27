import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  // Production URL (Render) - WebSocket connects to root, not /api
  static const String _baseUrl = 'https://rescueeats.onrender.com';
  // static const String _baseUrl = 'http://localhost:5001';
  late IO.Socket _socket;

  void connect(String userId, String userType) {
    _socket = IO.io(_baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.connect();

    _socket.onConnect((_) {
      _socket.emit('joinRoom', {'type': userType, 'id': userId});
    });
  }

  void disconnect() {
    _socket.disconnect();
  }

  void onOrderStatusUpdated(Function(dynamic) callback) {
    _socket.on('order:status_updated', (data) {
      callback(data);
    });
  }

  void onOrderCreated(Function(dynamic) callback) {
    _socket.on('order:created', (data) {
      callback(data);
    });
  }

  void leaveRoom(String userId) {
    _socket.emit('leaveRoom', {'type': 'customer', 'id': userId});
  }

  void onOrderAssigned(Function(dynamic) callback) {
    _socket.on('order:assigned', (data) {
      callback(data);
    });
  }

  void onOrderCancelled(Function(dynamic) callback) {
    _socket.on('order:cancelled', (data) {
      callback(data);
    });
  }

  void onPaymentReceived(Function(dynamic) callback) {
    _socket.on('order:payment_received', (data) {
      callback(data);
    });
  }
}

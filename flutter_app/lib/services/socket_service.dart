import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:codemania/config.dart';

class SocketService {
  static IO.Socket? _socket;

  static IO.Socket get socket {
    if (_socket == null) {
      throw Exception('Socket not initialized. Call connect() first.');
    }
    return _socket!;
  }

  static Future<void> connect() async {
    try {
      if (_socket != null && _socket!.connected) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      
      if (token == null) {
        throw Exception('User not authenticated. No JWT token found.');
      }

      Config.setToken(token);

      _socket?.dispose();
      _socket = IO.io(
        Config.socketUrl,
        IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .build(),
      );

      _socket!.onConnect((_) {
        print('✓ Socket.IO connected: ${_socket!.id}');
      });

      _socket!.onConnectError((err) {
        print('✗ Socket.IO connection error: $err');
      });

      _socket!.onDisconnect((_) {
        print('Socket.IO disconnected');
      });

      _socket!.onError((error) {
        print('Socket.IO error: $error');
      });
    } catch (e) {
      print('Socket connection error: $e');
      rethrow;
    }
  }

  static void joinContest(int contestId, int teamId, String userId) {
    socket.emit('join_contest', {
      'contestId': contestId,
      'teamId': teamId,
      'userId': userId,
    });
  }

  static void leaveContest(int contestId, int teamId) {
    socket.emit('leave_contest', {
      'contestId': contestId,
      'teamId': teamId,
    });
  }

  static void onSubmissionResult(Function(Map<String, dynamic>) callback) {
    socket.on('submission_result', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  static void clearSubmissionResultListeners() {
    _socket?.off('submission_result');
  }

  static void onLeaderboardUpdate(Function(Map<String, dynamic>) callback) {
    socket.on('leaderboard_update', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  static void onTeamFeedUpdate(Function(Map<String, dynamic>) callback) {
    socket.on('team_feed_update', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  static void disconnect() {
    if (_socket != null) {
      _socket!.emit('leave_contest', {});
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      print('✓ Socket.IO disconnected and cleaned up');
    }
  }

  static bool get isConnected => _socket?.connected ?? false;

  static void onContestJoined(Function(Map<String, dynamic>) callback) {
    socket.on('contest_joined', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  static void onTeamJoined(Function(Map<String, dynamic>) callback) {
    socket.on('team_joined', (data) {
      callback(data as Map<String, dynamic>);
    });
  }
}

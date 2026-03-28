import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:wisper/app/core/services/socket/call_services.dart';

class CallSocket {
  static void bind(IO.Socket socket, CallService callService) {
    socket.off('callIncoming');
    socket.off('callDeclined');
    socket.off('callEnded');
    socket.off('callCanceled');  

    socket.on('callIncoming', callService.handleCallIncoming);
    socket.on('callParticipantJoined', callService.handlecallParticipantJoined);
    socket.on('callDeclined', callService.handleCallDeclined);
    socket.on('callEnded', callService.handleCallEnded);
    socket.on('callCanceled', callService.handleCallCanceled);
  }

  static void unbind(IO.Socket socket) {
    socket.off('callIncoming');
    socket.off('callDeclined');
    socket.off('callEnded');
    socket.off('callCanceled');
  }
}

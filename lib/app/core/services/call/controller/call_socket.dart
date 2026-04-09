import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:wisper/app/core/services/call/controller/call_services.dart';

class CallSocket {
  static void bind(IO.Socket socket, CallService callService) {
    socket.off('callIncoming');
    socket.off('callDeclined');
    socket.off('callEnded');
    socket.off('callCanceled');  
    // ✅ NEW: participant join event
    socket.off('callParticipantJoined');
    socket.off('callParticipantsAccepted');

    socket.on('callIncoming', callService.handleCallIncoming);
    socket.on('callDeclined', callService.handleCallDeclined);
    socket.on('callEnded', callService.handleCallEnded);
    socket.on('callCanceled', callService.handleCallCanceled);
    // ✅ NEW: participant join event bind
    socket.on('callParticipantJoined', callService.handleParticipantJoined);
    socket.on('callParticipantsAccepted', callService.handleParticipantsAccepted);
  }

  static void unbind(IO.Socket socket) {
    socket.off('callIncoming');
    socket.off('callDeclined');
    socket.off('callEnded');
    socket.off('callCanceled');
    // ✅ NEW
    socket.off('callParticipantJoined');
    socket.off('callParticipantsAccepted');
  }
}

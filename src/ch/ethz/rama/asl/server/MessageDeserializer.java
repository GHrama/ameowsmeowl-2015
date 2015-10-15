package ch.ethz.rama.asl.server;

import java.nio.ByteBuffer;
import java.nio.channels.SocketChannel;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import ch.ethz.rama.asl.common.*;

public class MessageDeserializer {
	// aim is to breakdown each command sent by the client into
	// request(eg CREATE_QUEUE)
	// then parameter sent(like queue_name) and so on.
	final private static String end = "???";
	
	
	
	public static Map< MapParameters, String> decodeCommandToMap(String request){
		
		Map< MapParameters, String> commandparameters = new HashMap<MapParameters, String>();
		if (!request.endsWith(end))
			throw new IllegalArgumentException("does not end with ???");
			String[] parts = request.split(";");
			
			// to identify who the message is coming from,always add client_id
			String temp = parts[0];
			switch(temp){
			case "ADDQUEUE" :
				commandparameters.put(MapParameters.REQUEST_TYPE, RequestType.ADD_QUEUE.toString());
				commandparameters.put(MapParameters.CLIENT_ID, parts[1]);
				commandparameters.put(MapParameters.QUEUE_NAME, parts[2]);
				break;
			case "ADDCLIENT" :
				commandparameters.put(MapParameters.REQUEST_TYPE, RequestType.ADD_CLIENT.toString());
				commandparameters.put(MapParameters.CLIENT_NAME, parts[1]);
				break;
			case "DELETEQUEUE":
				commandparameters.put(MapParameters.REQUEST_TYPE, RequestType.DELETE_QUEUE.toString());
				commandparameters.put(MapParameters.CLIENT_ID, parts[1]);
				commandparameters.put(MapParameters.QUEUE_ID, parts[2]);
				break;
			case "SENDMSG" :
				commandparameters.put(MapParameters.REQUEST_TYPE, RequestType.SEND_MESSAGE.toString());
				commandparameters.put(MapParameters.QUEUE_ID, parts[1]);
				commandparameters.put(MapParameters.SENDER_ID, parts[2]);
				commandparameters.put(MapParameters.RECEIVER_ID, parts[3]);
				commandparameters.put(MapParameters.MESSAGE, parts[4]);
				break;
			case "RETVLATESTMSG":
				commandparameters.put(MapParameters.REQUEST_TYPE, RequestType.RETV_LATEST_MESSAGE.toString());
				commandparameters.put(MapParameters.QUEUE_ID, parts[1]);
				commandparameters.put(MapParameters.RECEIVER_ID, parts[2]);
				break;
			case "RETVLATESTMSGDELETE" :
				commandparameters.put(MapParameters.REQUEST_TYPE, RequestType.RETV_LATEST_MESSAGE_DELETE.toString());
				commandparameters.put(MapParameters.QUEUE_ID, parts[1]);
				commandparameters.put(MapParameters.RECEIVER_ID, parts[2]);
				break;
			case "RETVSENDERMSG" :
				commandparameters.put(MapParameters.REQUEST_TYPE, RequestType.RETV_SENDER_MESSAGE.toString());
				commandparameters.put(MapParameters.QUEUE_ID, parts[1]);
				commandparameters.put(MapParameters.SENDER_ID, parts[2]);
				commandparameters.put(MapParameters.RECEIVER_ID, parts[3]);
				break;
			case "RETVSENDERMSGDELETE" :
				commandparameters.put(MapParameters.REQUEST_TYPE, RequestType.RETV_SENDER_MESSAGE_DELETE.toString());
				commandparameters.put(MapParameters.QUEUE_ID, parts[1]);
				commandparameters.put(MapParameters.SENDER_ID, parts[2]);
				commandparameters.put(MapParameters.RECEIVER_ID, parts[3]);
				break;
			case "QUEUESWITHMSG":
				commandparameters.put(MapParameters.REQUEST_TYPE, RequestType.QUEUES_WITH_MESSAGE.toString());
				commandparameters.put(MapParameters.RECEIVER_ID, parts[1]);
				break;
				default:
				throw new IllegalArgumentException(String.format(
						"Message {%s} has request_type %s.", request, temp ));
				
				}
		
		
		return commandparameters;
	}
	
	public static void main(String[] args) {
		String[] samples = { "ADDQUEUE;42;abc;???",
				"DELETEQUEUE;100;23;???", "SENDMSG;45;10;20;Hello world!;???",
				"RETVLATESTMSG;12;43;???", "RETVSENDERMSG;90;101;123;???",
				"QUEUESWITHMSG;55;???" };

		for (String smp : samples) {
			System.out.println(decodeCommandToMap(smp));
		}
	}

}

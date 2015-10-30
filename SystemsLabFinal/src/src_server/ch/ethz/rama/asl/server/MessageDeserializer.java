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
	final private static String end = "?";
	
	
	
	public static Map< MapParameters, String> decodeCommandToMap(String request){
		
		Map< MapParameters, String> commandparameters = new HashMap<MapParameters, String>();
		if (!request.endsWith(end))
			throw new IllegalArgumentException("does not end with ?");
			String[] parts = request.split(";");
			
			// to identify who the message is coming from,always add client_id
			String temp = parts[0];
			switch(temp){
			case "ADDQUEUE" :
				commandparameters.put(MapParameters.REQUEST_TYPE, Type.ADD_QUEUE.toString());
				commandparameters.put(MapParameters.CLIENT_ID, parts[1]);
				commandparameters.put(MapParameters.QUEUE_NAME, parts[2]);
				break;
			case "ADDCLIENT" :
				commandparameters.put(MapParameters.REQUEST_TYPE, Type.ADD_CLIENT.toString());
				commandparameters.put(MapParameters.CLIENT_NAME, parts[1]);
				break;
			case "DELQUEUE":
				commandparameters.put(MapParameters.REQUEST_TYPE, Type.DEL_QUEUE.toString());
				commandparameters.put(MapParameters.CLIENT_ID, parts[1]);
				commandparameters.put(MapParameters.QUEUE_ID, parts[2]);
				break;
			case "SENDMSG" :
				commandparameters.put(MapParameters.REQUEST_TYPE, Type.SEND_MSG.toString());
				commandparameters.put(MapParameters.QUEUE_ID, parts[1]);
				commandparameters.put(MapParameters.SENDER_ID, parts[2]);
				commandparameters.put(MapParameters.RECEIVER_ID, parts[3]);
				commandparameters.put(MapParameters.MESSAGE, parts[4]);
				break;
			case "GETLATESTMSG":
				commandparameters.put(MapParameters.REQUEST_TYPE, Type.GET_LATEST_MSG.toString());
				commandparameters.put(MapParameters.QUEUE_ID, parts[1]);
				commandparameters.put(MapParameters.RECEIVER_ID, parts[2]);
				break;
			case "GETLATESTMSGDEL" :
				commandparameters.put(MapParameters.REQUEST_TYPE, Type.GET_LATEST_MSG_DEL.toString());
				commandparameters.put(MapParameters.QUEUE_ID, parts[1]);
				commandparameters.put(MapParameters.RECEIVER_ID, parts[2]);
				break;
			case "GETSENDERMSG" :
				commandparameters.put(MapParameters.REQUEST_TYPE, Type.GET_SENDER_MSG.toString());
				commandparameters.put(MapParameters.QUEUE_ID, parts[1]);
				commandparameters.put(MapParameters.SENDER_ID, parts[2]);
				commandparameters.put(MapParameters.RECEIVER_ID, parts[3]);
				break;
			case "GETSENDERMSGDEL" :
				commandparameters.put(MapParameters.REQUEST_TYPE, Type.GET_SENDER_MSG_DEL.toString());
				commandparameters.put(MapParameters.QUEUE_ID, parts[1]);
				commandparameters.put(MapParameters.SENDER_ID, parts[2]);
				commandparameters.put(MapParameters.RECEIVER_ID, parts[3]);
				break;
			case "GETQUEUES":
				commandparameters.put(MapParameters.REQUEST_TYPE, Type.GET_QUEUES.toString());
				commandparameters.put(MapParameters.RECEIVER_ID, parts[1]);
				break;
				default:
				throw new IllegalArgumentException(String.format(
						"Message {%s} has request_type %s.", request, temp ));
				
				}
		
		
		return commandparameters;
	}
	
	public static void main(String[] args) {
		
	}

}

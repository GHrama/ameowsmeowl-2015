package ch.ethz.rama.asl.server;

import java.nio.ByteBuffer;
import java.nio.channels.SocketChannel;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;


import ch.ethz.rama.asl.common.MapParameters;
import ch.ethz.rama.asl.common.RequestType;
import ch.ethz.rama.asl.database.DatabaseAPI;

// message worker threads
// adapted from http://rox-xmlrpc.sourceforge.net/niotut/
import org.postgresql.ds.PGPoolingDataSource;
public class MessageWorker implements Runnable {
	MessageServer server;
	SocketChannel socketchannel;
	
	int bufferlength;
	int begin_wait_worker;
	ServerDataEvent dataevent;
	String end;
	PGPoolingDataSource dbsource;
	DatabaseAPI dbapi;
	
	
	// will add pgpooling soon
	public MessageWorker(PGPoolingDataSource dbsource, MessageServer server,SocketChannel sc, byte[] bs,int bufferlength, int start_wait_for_begin){
		end = "???";
		this.server = server;
		this.socketchannel = sc;
		this.dbsource = dbsource;
		this.bufferlength = bufferlength;
		this.begin_wait_worker =start_wait_for_begin; //just the time when the server wait for worker to start working on the read request
		byte[] dataCopy = new byte[bufferlength];
		System.arraycopy(bs, 0, dataCopy, 0, this.bufferlength);
		// used to send easily
		this.dataevent = new ServerDataEvent(this.server,this.socketchannel,dataCopy);
		this.dbapi = new DatabaseAPI();
	}
	
	public void run(){
		
		String request = new String(dataevent.data);
		String response = String.format("ERROR", end); // all repsonse request end with ???
		long beginDBResponseTime,dbWaitTime;
		Connection connection = null;
		Map< MapParameters, String> commandparameters = MessageDecoder.decodeCommandToMap(request) ;
		try{
			switch(commandparameters.get(MapParameters.REQUEST_TYPE)){
		
		case "ADDQUEUE" :
			String queueName = commandparameters.get(MapParameters.QUEUE_NAME);
			//beginDBResponseTime = System.currentTimeMillis();
			connection = dbsource.getConnection();
			//dbWaitTime = System.currentTimeMillis() - beginDBResponseTime;
			int queueID = dbapi.addNewQueue(connection, queueName);
			connection.close();
			response = String.format("%s-%d-%s", RequestType.ADD_QUEUE,
					queueID, end);
			break;
		case "ADDCLIENT" :
			String clientname = commandparameters.get(MapParameters.CLIENT_NAME);
			connection = dbsource.getConnection();
			int client_id = dbapi.addClient(connection, clientname);
			connection.close();
			response = String.format("%s-%d-%s", RequestType.ADD_CLIENT,
					client_id, end);
			break;
		case "DELETEQUEUE":
			int queue_id = Integer.parseInt((commandparameters.get(MapParameters.QUEUE_ID)));
			connection = dbsource.getConnection();
			int success = dbapi.deleteQueue(connection, queue_id);
			connection.close();
			response = String.format("%s-%d-%s", RequestType.DELETE_QUEUE,
					success, end);
			break;
		case "SENDMSG" :
			int sender_id = Integer.parseInt((commandparameters.get(MapParameters.SENDER_ID)));
			int receiver_id = Integer.parseInt((commandparameters.get(MapParameters.RECEIVER_ID)));
			int queueid = Integer.parseInt((commandparameters.get(MapParameters.QUEUE_ID)));
			String payload = (commandparameters.get(MapParameters.MESSAGE));
			connection = dbsource.getConnection();
			int msg_id = dbapi.addMesssage(connection, queueid, sender_id, receiver_id, payload);
			connection.close();
			response = String.format("%s-%d-%s", RequestType.SEND_MESSAGE,
					msg_id, end);
			break;
		case "RETVLATESTMSG":
			
			int receiverid = Integer.parseInt((commandparameters.get(MapParameters.RECEIVER_ID)));
			int qid = Integer.parseInt((commandparameters.get(MapParameters.QUEUE_ID)));
			connection = dbsource.getConnection();
			String msg = dbapi.getLatestMessage(connection, qid, receiverid);
			connection.close();
			response = String.format("%s-%s-%s", RequestType.RETV_LATEST_MESSAGE,
					msg, end);
			break;
		case "RETVLATESTMSGDELETE" :
			int receiveid = Integer.parseInt((commandparameters.get(MapParameters.RECEIVER_ID)));
			int qd = Integer.parseInt((commandparameters.get(MapParameters.QUEUE_ID)));
			connection = dbsource.getConnection();
			String m = dbapi.getLatestMessageDelete(connection, qd, receiveid);
			connection.close();
			response = String.format("%s-%s-%s", RequestType.RETV_LATEST_MESSAGE,
					m, end);
			break;
		case "RETVSENDERMSG" :
			int receivid = Integer.parseInt((commandparameters.get(MapParameters.RECEIVER_ID)));
			int q = Integer.parseInt((commandparameters.get(MapParameters.QUEUE_ID)));
			int senderid = Integer.parseInt(commandparameters.get(MapParameters.SENDER_ID));
			connection = dbsource.getConnection();
			String t = dbapi.latestMessageFromSender(connection, q, senderid, receivid);
			connection.close();
			response = String.format("%s-%s-%s", RequestType.RETV_SENDER_MESSAGE,
					t, end);
			break;
		case "RETVSENDERMSGDELETE" :
			int receiid = Integer.parseInt((commandparameters.get(MapParameters.RECEIVER_ID)));
			int qt = Integer.parseInt((commandparameters.get(MapParameters.QUEUE_ID)));
			int sendeid = Integer.parseInt(commandparameters.get(MapParameters.SENDER_ID));
			connection = dbsource.getConnection();
			String th = dbapi.latestMessageFromSenderDelete(connection, qt, sendeid, receiid);
			connection.close();
			response = String.format("%s-%s-%s", RequestType.RETV_SENDER_MESSAGE_DELETE,
					th, end);
		break;
		case "QUEUESWITHMSG":
			int clientid = Integer.parseInt(commandparameters.get(MapParameters.CLIENT_ID));
			connection = dbsource.getConnection();
			List<Integer> queueList = dbapi.getQueuesWithMessage(connection, clientid);
			connection.close();
			StringBuilder queueStrBuilder = new StringBuilder();
			String prefix = "";
			for (int i : queueList) {
				queueStrBuilder.append(prefix);
				prefix = "&";
				queueStrBuilder.append(i);
			}
			response = String.format("%s-%s-%s", RequestType.QUEUES_WITH_MESSAGE,
					queueStrBuilder, end);
			break;
			default:
			//throw new IllegalArgumentException(String.format(
			//		"Message {%s} has request_type %s.", request,  ));
			
			}
		}catch(SQLException e){
			String expDescription = e.getMessage();
			response = String.format("%s-%s-%s-%s", "EXCEPTION", request,
					expDescription, end);
			e.printStackTrace();
			
		} catch (NumberFormatException e) {
			e.printStackTrace();
			System.err.println(request);
			System.err.println(commandparameters);
			throw e;
		} finally {
			if (connection != null) {
				try {
					if (!connection.isClosed())
						connection.close();
				} catch (SQLException e) {
					e.printStackTrace();
				}
			}
		}
		
		// Illegal access exception ?
		
		this.dataevent.server.send(dataevent.socket, response.getBytes());
			
		}
		
		
		
		
	}



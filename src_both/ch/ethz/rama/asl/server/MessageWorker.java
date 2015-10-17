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
import ch.ethz.rama.asl.pool.ConnectionPool;

// message worker threads
// adapted from http://rox;xmlrpc.sourceforge.net/niotut/

public class MessageWorker implements Runnable {
	MessageServer server;
	SocketChannel socketchannel;
	
	int bufferlength;
	int begin_wait_worker;
	ServerDataEvent dataevent;
	String end;
	ConnectionPool pool;
	DatabaseAPI dbapi;
	
	
	// will add pgpooling soon
	public MessageWorker(ConnectionPool pool, MessageServer server,SocketChannel sc, byte[] bs,int bufferlength, int start_wait_for_begin){
		end = "???";
		this.server = server;
		this.socketchannel = sc;
		this.pool = pool;
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
		Map< MapParameters, String> commandparameters = MessageDeserializer.decodeCommandToMap(request) ;
		try{
			switch(commandparameters.get(MapParameters.REQUEST_TYPE)){
		
		case "ADDQUEUE" :
			String queueName = commandparameters.get(MapParameters.QUEUE_NAME);
			//beginDBResponseTime = System.currentTimeMillis();
				try {
					connection = pool.borrowConnection();
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
					
				}
			//dbWaitTime = System.currentTimeMillis() ; beginDBResponseTime;
			int queueID = dbapi.addNewQueue(connection, queueName);
			pool.returnConnection(connection);
			response = String.format("%s;%d;%s", RequestType.ADD_QUEUE,
					queueID, end);
			break;
		case "ADDCLIENT" :
			String clientname = commandparameters.get(MapParameters.CLIENT_NAME);
				try {
					connection = pool.borrowConnection();
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			int client_id = dbapi.addClient(connection, clientname);
			pool.returnConnection(connection);
			response = String.format("%s;%d;%s", RequestType.ADD_CLIENT,
					client_id, end);
			break;
		case "DELETEQUEUE":
			int queue_id = Integer.parseInt((commandparameters.get(MapParameters.QUEUE_ID)));
				
				try {
					connection = pool.borrowConnection();
				} catch (InterruptedException e1) {
					// TODO Auto-generated catch block
					e1.printStackTrace();
				}
				 
			int success = dbapi.deleteQueue(connection, queue_id);
			pool.returnConnection(connection);
			response = String.format("%s;%d;%s", RequestType.DELETE_QUEUE,
					success, end);
			break;
		case "SENDMSG" :
			int sender_id = Integer.parseInt((commandparameters.get(MapParameters.SENDER_ID)));
			int receiver_id = Integer.parseInt((commandparameters.get(MapParameters.RECEIVER_ID)));
			int queueid = Integer.parseInt((commandparameters.get(MapParameters.QUEUE_ID)));
			String payload = (commandparameters.get(MapParameters.MESSAGE));
				try {
					connection = pool.borrowConnection();
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			int msg_id = dbapi.addMesssage(connection, queueid, sender_id, receiver_id, payload);
			pool.returnConnection(connection);
			response = String.format("%s;%d;%s", RequestType.SEND_MESSAGE,
					msg_id, end);
			break;
		case "RETVLATESTMSG":
			
			int receiverid = Integer.parseInt((commandparameters.get(MapParameters.RECEIVER_ID)));
			int qid = Integer.parseInt((commandparameters.get(MapParameters.QUEUE_ID)));
				try {
					connection = pool.borrowConnection();
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			String msg = dbapi.getLatestMessage(connection, qid, receiverid);
			pool.returnConnection(connection);
			response = String.format("%s;%s;%s", RequestType.RETV_LATEST_MESSAGE,
					msg, end);
			break;
		case "RETVLATESTMSGDELETE" :
			int receiveid = Integer.parseInt((commandparameters.get(MapParameters.RECEIVER_ID)));
			int qd = Integer.parseInt((commandparameters.get(MapParameters.QUEUE_ID)));
				try {
					connection = pool.borrowConnection();
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			String m = dbapi.getLatestMessageDelete(connection, qd, receiveid);
			pool.returnConnection(connection);
			response = String.format("%s;%s;%s", RequestType.RETV_LATEST_MESSAGE,
					m, end);
			break;
		case "RETVSENDERMSG" :
			int receivid = Integer.parseInt((commandparameters.get(MapParameters.RECEIVER_ID)));
			int q = Integer.parseInt((commandparameters.get(MapParameters.QUEUE_ID)));
			int senderid = Integer.parseInt(commandparameters.get(MapParameters.SENDER_ID));
				try {
					connection = pool.borrowConnection();
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			String t = dbapi.latestMessageFromSender(connection, q, senderid, receivid);
			pool.returnConnection(connection);
			response = String.format("%s;%s;%s", RequestType.RETV_SENDER_MESSAGE,
					t, end);
			break;
		case "RETVSENDERMSGDELETE" :
			int receiid = Integer.parseInt((commandparameters.get(MapParameters.RECEIVER_ID)));
			int qt = Integer.parseInt((commandparameters.get(MapParameters.QUEUE_ID)));
			int sendeid = Integer.parseInt(commandparameters.get(MapParameters.SENDER_ID));
				try {
					connection = pool.borrowConnection();
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			String th = dbapi.latestMessageFromSenderDelete(connection, qt, sendeid, receiid);
			pool.returnConnection(connection);
			response = String.format("%s;%s;%s", RequestType.RETV_SENDER_MESSAGE_DELETE,
					th, end);
		break;
		case "QUEUESWITHMSG":
			int clientid = Integer.parseInt(commandparameters.get(MapParameters.RECEIVER_ID));
				try {
					connection = pool.borrowConnection();
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			List<Integer> queueList = dbapi.getQueuesWithMessage(connection, clientid);
			pool.returnConnection(connection);
			StringBuilder queueStrBuilder = new StringBuilder();
			String prefix = "";
//			if(queueList.get(0) == -10000)
//				queueStrBuilder.append(-10000);
//			else
			if(queueList != null){
			for (int i : queueList) {
				queueStrBuilder.append(prefix);
				prefix = "&";
				queueStrBuilder.append(i);
			}
			}
			response = String.format("%s;%s;%s", RequestType.QUEUES_WITH_MESSAGE,
					queueStrBuilder, end);
			break;
			default:
			//throw new IllegalArgumentException(String.format(
			//		"Message {%s} has request_type %s.", request,  ));
			
			}
		}catch(SQLException e){
			// what is code when queue does not exist
			System.out.println("sql exception number:: "+Integer.parseInt(e.getSQLState()));
			System.out.println(e.getMessage());
			String expDescription = e.getMessage();
			response = String.format("%s;%s;%s;%s", "EXCEPTION", request,
					expDescription, end);
//			e.printStackTrace();
			
		} catch (NumberFormatException e) {
			e.printStackTrace();
			System.err.println(request);
			System.err.println(commandparameters);
			throw e;
		} finally {
			if (connection != null) {
				pool.returnConnection(connection);
			}
		}
		
		// Illegal access exception ?
		
		this.dataevent.server.send(dataevent.socket, response.getBytes());
			
		}
		
		
		
		
	}



package ch.ethz.rama.asl.server;

import java.nio.ByteBuffer;
import java.nio.channels.SocketChannel;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;

import ch.ethz.rama.asl.common.MapParameters;
import ch.ethz.rama.asl.common.Type;
import ch.ethz.rama.asl.database.DatabaseAPI;
import ch.ethz.rama.asl.logging.MyLogger;
import ch.ethz.rama.asl.pool.ConnectionPool;


// message worker threads
// adapted from http://rox;xmlrpc.sourceforge.net/niotut/

public class MessageWorker implements Runnable {
	public final static Logger loggerWorker = MyLogger.classLogger(MessageWorker.class.getName(),"serverworker-");
	MessageServer server;
	SocketChannel socketchannel;
	
	int bufferlength;
	long begin_wait_worker;
	ServerDataEvent dataevent;
	String end;
	ConnectionPool pool;
	DatabaseAPI dbapi;
	
	
	// will add pgpooling soon
	public MessageWorker(ConnectionPool pool, MessageServer server,SocketChannel sc, byte[] bs,int bufferlength, long start_wait_for_begin){
		end = "?";
		this.server = server;
		this.socketchannel = sc;
		this.pool = pool;
		this.bufferlength = bufferlength;
		this.begin_wait_worker = start_wait_for_begin; //just the time when the server wait for worker to start working on the read request
		byte[] dataCopy = new byte[bufferlength];
		System.arraycopy(bs, 0, dataCopy, 0, this.bufferlength);
		// used to send easily
		this.dataevent = new ServerDataEvent(this.server,this.socketchannel,dataCopy);
		this.dbapi = new DatabaseAPI();
	}
	
	public void run(){
		long begin_service = System.currentTimeMillis();
		long start_db_response = 0,wait_at_db = 0;
		long wait_at_server_queue = 0;
		wait_at_server_queue = System.currentTimeMillis() - this.begin_wait_worker;
		long db_response_time;
		String whattype = null;
		String request = new String(dataevent.data);
		String response = String.format("ERROR", end); // all repsonse request end with ???
		//long beginDBResponseTime,dbWaitTime;
		Connection connection = null;
		Map< MapParameters, String> commandparameters = MessageDeserializer.decodeCommandToMap(request) ;
		try{
			switch(commandparameters.get(MapParameters.REQUEST_TYPE)){
		
		case "ADDQUEUE" :
			whattype = "ADD_QUEUE";
			String queueName = commandparameters.get(MapParameters.QUEUE_NAME);
			
			//beginDBResponseTime = System.currentTimeMillis();
				try {
					start_db_response = System.currentTimeMillis();
					connection = pool.getConnection();
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
					
				}
			//dbWaitTime = System.currentTimeMillis() ; beginDBResponseTime;
			wait_at_db = System.currentTimeMillis() - start_db_response;
			int queueID = dbapi.addNewQueue(connection, queueName);
			pool.returnConnection(connection);
			//whattype - wait_at_db - db_response_time - wait-at-server-queue
			db_response_time = System.currentTimeMillis() - start_db_response;
			response = String.format("%s;%d;%s", Type.ADD_QUEUE,
					queueID, end);
			break;
		case "ADDCLIENT" :
			whattype = "ADD_CLIENT";
			String clientname = commandparameters.get(MapParameters.CLIENT_NAME);
				try {
					connection = pool.getConnection();
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			int client_id = dbapi.addClient(connection, clientname);
			pool.returnConnection(connection);
			response = String.format("%s;%d;%s", Type.ADD_CLIENT,
					client_id, end);
			break;
		case "DELQUEUE":
			whattype = "DELETE_QUEUE";
			int queue_id = Integer.parseInt((commandparameters.get(MapParameters.QUEUE_ID)));
				
				try {
					connection = pool.getConnection();
				} catch (InterruptedException e1) {
					// TODO Auto-generated catch block
					e1.printStackTrace();
				}
				 
			int success = dbapi.deleteQueue(connection, queue_id);
			pool.returnConnection(connection);
			response = String.format("%s;%d;%s", Type.DEL_QUEUE,
					success, end);
			break;
		case "SENDMSG" :
			whattype = "SEND_MSG";
			int sender_id = Integer.parseInt((commandparameters.get(MapParameters.SENDER_ID)));
			int receiver_id = Integer.parseInt((commandparameters.get(MapParameters.RECEIVER_ID)));
			int queueid = Integer.parseInt((commandparameters.get(MapParameters.QUEUE_ID)));
			String payload = (commandparameters.get(MapParameters.MESSAGE));
				try {
					start_db_response = System.currentTimeMillis();
					connection = pool.getConnection();
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			wait_at_db = System.currentTimeMillis() - start_db_response;
			int msg_id = dbapi.addMesssage(connection, queueid, sender_id, receiver_id, payload);
			pool.returnConnection(connection);
			db_response_time = System.currentTimeMillis() - start_db_response;
			
			response = String.format("%s;%d;%s", Type.SEND_MSG,
					msg_id, end);
			break;
		case "GETLATESTMSG":
			whattype = "GET_LATEST_MSG";
			int receiverid = Integer.parseInt((commandparameters.get(MapParameters.RECEIVER_ID)));
			int qid = Integer.parseInt((commandparameters.get(MapParameters.QUEUE_ID)));
				try {
					connection = pool.getConnection();
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			String msg = dbapi.getLatestMessage(connection, qid, receiverid);
			pool.returnConnection(connection);
			response = String.format("%s;%s;%s", Type.GET_LATEST_MSG,
					msg, end);
			break;
		case "GETLATESTMSGDEL" :
			whattype = "GET_LATEST_MSG_DELETE";
			int receiveid = Integer.parseInt((commandparameters.get(MapParameters.RECEIVER_ID)));
			int qd = Integer.parseInt((commandparameters.get(MapParameters.QUEUE_ID)));
				try {
					start_db_response = System.currentTimeMillis();
					connection = pool.getConnection();
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			wait_at_db = System.currentTimeMillis() - start_db_response;
			String m = dbapi.getLatestMessageDelete(connection, qd, receiveid);
			pool.returnConnection(connection);
			db_response_time = System.currentTimeMillis() - start_db_response;
			response = String.format("%s;%s;%s", Type.GET_LATEST_MSG_DEL,
					m, end);
			break;
		case "GETSENDERMSG" :
			whattype = "GET_SENDER_MSG";
			int receivid = Integer.parseInt((commandparameters.get(MapParameters.RECEIVER_ID)));
			int q = Integer.parseInt((commandparameters.get(MapParameters.QUEUE_ID)));
			int senderid = Integer.parseInt(commandparameters.get(MapParameters.SENDER_ID));
				try {
					connection = pool.getConnection();
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			String t = dbapi.latestMessageFromSender(connection, q, senderid, receivid);
			pool.returnConnection(connection);
			response = String.format("%s;%s;%s", Type.GET_SENDER_MSG,
					t, end);
			break;
		case "GETSENDERMSGDEL" :
			whattype = "GET_SENDER_MSG_DELETE";
			int receiid = Integer.parseInt((commandparameters.get(MapParameters.RECEIVER_ID)));
			int qt = Integer.parseInt((commandparameters.get(MapParameters.QUEUE_ID)));
			int sendeid = Integer.parseInt(commandparameters.get(MapParameters.SENDER_ID));
				try {
					connection = pool.getConnection();
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			String th = dbapi.latestMessageFromSenderDelete(connection, qt, sendeid, receiid);
			pool.returnConnection(connection);
			response = String.format("%s;%s;%s", Type.GET_SENDER_MSG_DEL,
					th, end);
		break;
		case "GETQUEUES":
			whattype = "GET_QUEUE";
			int clientid = Integer.parseInt(commandparameters.get(MapParameters.RECEIVER_ID));
				try {
					start_db_response = System.currentTimeMillis();
					connection = pool.getConnection();
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			wait_at_db = System.currentTimeMillis() - start_db_response;
			List<Integer> queueList = dbapi.getQueuesWithMessage(connection, clientid);
			pool.returnConnection(connection);
			db_response_time = System.currentTimeMillis() - start_db_response;
			StringBuilder queueStrBuilder = new StringBuilder();
			String prefix = "";
//			if(queueList.get(0) == -10000)
//				queueStrBuilder.append(-10000);
//			else
			
			for (int i : queueList) {
				queueStrBuilder.append(prefix);
				prefix = "&";
				queueStrBuilder.append(i);
			}
			
			response = String.format("%s;%s;%s", Type.GET_QUEUES,
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
		long time = System.currentTimeMillis()-begin_wait_worker;
		//time the selector assigns a worker thread,worker thread execution time
		// TIME TYPE RESPONSE_TIME_OF_MIDDLEWARE
		// TIME TYPE WAIT_AT_DB RESPONSE_DB_TIME WAIT_AT_SERVER TIME_SERVICE_WORKER
		loggerWorker.info(whattype+","+wait_at_db+","+(System.currentTimeMillis()-start_db_response)+","+wait_at_server_queue+","+time);
			
		}
		
		
		
		
	}



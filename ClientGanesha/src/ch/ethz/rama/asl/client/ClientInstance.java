package ch.ethz.rama.asl.client;

import java.io.FileInputStream;
import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

import ch.ethz.rama.asl.exceptions.GaneshaQueueException;

// Client make an instance of this in a thread
// 
// TODO add exception for adding msg to non existing queues

public class ClientInstance {
	public ClientInstance(int id) throws Exception{
		// get info from property file
		String sp = "/local/rsridhar/01/properties/client.properties";
//		String sp = "/Users/ramapriyasridharan/Documents/Dryad01/client.properties";
		Properties p = new Properties();
		try{
			p.load(new FileInputStream(sp));
			this.buffersize = Integer.parseInt(p.getProperty("ms").trim());
			this.serverhost = p.getProperty("serverhost");
			this.serverport = Integer.parseInt(p.getProperty("serverport").trim());
//			this.buffersize = 200;
//			this.serverhost = "dryad04.ethz.ch";
//			this.serverport = 5544;
			
			//this.clientid = id;
		
			this.clientapi = new ClientCore(this.serverhost,this.serverport, buffersize);
			//once instantiated, register the client
			this.clientid = id;
		} catch (IOException e) {
			// TODO Auto;generated catch block
			e.printStackTrace();
		}
		
	}
	public int clientid;
	ClientCore clientapi;
	int buffersize;
	String serverhost;
	int serverport;
	
	public int addQueue(String name) throws GaneshaQueueException{
		ResponseHandler handler = new ResponseHandler();
		String msg = ClientSerializer.eAddQueue(clientid, name);
		// msg = ADDQUEUE;42;abc;???
		// response = ADDQUEUE;queueid;???
		try {
			clientapi.send(msg.getBytes(), handler);
		} catch (IOException e) {
			// TODO Auto;generated catch block
			e.printStackTrace();
		}
		// decode it
		String response = handler.waitForResponse();
		String[] answer = response.split(";");
		int ans = Integer.parseInt(answer[1]);
		//System.out.println(response);
		if(ans < 0){
			throw new GaneshaQueueException("Queue was not added to database");
		}
		return ans;
	}
	
	public int addClient(int clientid) throws GaneshaQueueException{
		ResponseHandler handler = new ResponseHandler();
		String msg = ClientSerializer.eAddClient(clientid);
		// msg = ADDCLIENT;client;???
		// response = ADDCLIENT;clientid;???
		try {
			clientapi.send(msg.getBytes(), handler);
		} catch (IOException e) {
			// TODO Auto;generated catch block
			e.printStackTrace();
		}
		String response = handler.waitForResponse();
		String[] answer = response.split(";");
		if(answer[0]=="EXCEPTION"){
			String err = answer[2];
			throw new GaneshaQueueException("Queue does not exist");
		}
		int ans = Integer.parseInt(answer[1]);
//		System.out.println(ans);
		return ans;
	}
	public int deleteQueue(int clientid, int queueid) throws GaneshaQueueException{
		ResponseHandler handler = new ResponseHandler();
		String msg = ClientSerializer.eDeleteQueue(clientid,queueid);
		// msg =DELETEQUEUE;clientid;queueid;???
		// response = DELETEQUEUE;success;???
		try {
			clientapi.send(msg.getBytes(), handler);
		} catch (IOException e) {
			// TODO Auto;generated catch block
			e.printStackTrace();
		}
		String response = handler.waitForResponse();
		String[] answer = response.split(";");
		int ans = Integer.parseInt(answer[1]);
//		System.out.println(response);
		
		//		System.out.println(ans);
		if( ans!= 1){
			throw new GaneshaQueueException("Queue was not deleted");
		}
		return ans;
	}
	
	public int sendMessage(int queueid,int senderid, int receiverid, String msg1) throws GaneshaQueueException{
		ResponseHandler handler = new ResponseHandler();
		String msg = ClientSerializer.eSendMessage(queueid,senderid,receiverid,msg1);
		// msg = SENDMSG;queueid;senderid;receiverid;payload;???
		// response = SENDMSG;msgid;???
		try {
			clientapi.send(msg.getBytes(), handler);
		} catch (IOException e) {
			// TODO Auto;generated catch block
			e.printStackTrace();
		}
		String response = handler.waitForResponse();
		String[] answer = response.split(";");
		int ans = Integer.parseInt(answer[1]);
		if( ans < -1000){
			throw new GaneshaQueueException("Queue does not exist");
		}
//		System.out.println(response);
//		System.out.println(ans);
		return ans;
	}
	//says null,need to send back more stuff
	//pgsql exception
	public String retreiveLatestMessage(int queueid, int receiverid) throws GaneshaQueueException{
		ResponseHandler handler = new ResponseHandler();
		String msg = ClientSerializer.eRetrieveLatestMessage(queueid, receiverid);
		// msg = ADDCLIENT;client;???
		// response = RETVLATESTMESSAGE;message;???
		try {
			clientapi.send(msg.getBytes(), handler);
		} catch (IOException e) {
			// TODO Auto;generated catch block
			e.printStackTrace();
		}
		String response = handler.waitForResponse();
		String[] answer = response.split(";");
		
		if(answer[0]=="EXCEPTION"){
			String err = answer[2];
			throw new GaneshaQueueException("Queue does not exist");
		}
		String ans = (answer[1]);
//		System.out.println(response);
//		System.out.println(ans);
		return ans;
	}
	
	public String retreiveLatestMessageDelete(int queueid, int receiverid) throws GaneshaQueueException{
		ResponseHandler handler = new ResponseHandler();
		String msg = ClientSerializer.eRetrieveLatestMessageDelete(queueid, receiverid);
		// msg = RETVLATESTMSGDELETE;queueid;receiverid;???
		// response = RETVLATESTMSGDELETE;message;???
		try {
			clientapi.send(msg.getBytes(), handler);
		} catch (IOException e) {
			// TODO Auto;generated catch block
			e.printStackTrace();
		}
		String response = handler.waitForResponse();
		String[] answer = response.split(";");
		
		if(answer[0]=="EXCEPTION"){
			String err = answer[2];
			throw new GaneshaQueueException("Queue does not exist");
		}
//		System.out.println(response);
		String ans = (answer[1]);
//		System.out.println(ans);
		return ans;
	}
	
	public String retreiveMessageFromSender(int queueid, int receiverid,int senderid) throws Exception{
		ResponseHandler handler = new ResponseHandler();
		String msg = ClientSerializer.eRetrieveMessageFromSender(queueid, receiverid,senderid);
		// msg = RETVSENDERMSG;queueid;receiverid;senderid;???
		// response = RETVSENDERMESSAGE;msg;???
		try {
			clientapi.send(msg.getBytes(), handler);
		} catch (IOException e) {
			// TODO Auto;generated catch block
			e.printStackTrace();
		}
		String response = handler.waitForResponse();
		String[] answer = response.split(";");
		if(answer[0]=="EXCEPTION"){
			String err = answer[2];
			throw new GaneshaQueueException("Queue does not exist");
		}
		String ans = (answer[1]);
//		System.out.println(response);
//	System.out.println(ans);
		return ans;
	}
	
	public String retreiveMessageFromSenderDelete(int queueid, int receiverid,int senderid) throws GaneshaQueueException{
		ResponseHandler handler = new ResponseHandler();
		String msg = ClientSerializer.eRetrieveMessageFromSenderDelete(queueid, receiverid,senderid);
		// msg = RETVSENDERMSGDELETE;queueid;receiverid;senderid;???
		// response = RETVSENDERDELETE;msg;???
		try {
			clientapi.send(msg.getBytes(), handler);
		} catch (IOException e) {
			// TODO Auto;generated catch block
			e.printStackTrace();
		}
		String response = handler.waitForResponse();
		String[] answer = response.split(";");
		
		if(answer[0]=="EXCEPTION"){
			String err = answer[2];
			throw new GaneshaQueueException("Queue does not exist");
		}
//		System.out.println(response);
		String ans = (answer[1]);
//		System.out.println(ans);
		return ans;
	}
	
	public List<Integer> queuesWithMessage(int clientid) throws GaneshaQueueException{
		ResponseHandler handler = new ResponseHandler();
		String msg = ClientSerializer.eQueuesWithMessages(clientid);
		// msg = QUEUESWITHMSG;clientid;???
		// response = QUEUESWITHMSG;
		try {
			clientapi.send(msg.getBytes(), handler);
		} catch (IOException e) {
			// TODO Auto;generated catch block
			e.printStackTrace();
		}
		String response = handler.waitForResponse();
		
//		System.out.println("response::"+response);
		String[] answer = response.split(";");
//		System.out.println(answer);
//		System.out.println(answer[1]);
		
		if(answer[0]=="EXCEPTION"){
			String err = answer[2];
			throw new GaneshaQueueException(err);
		}
		String[] ans = answer[1].split("&");
//		System.out.println(ans);
//		System.out.println(response);
		List<Integer> q = new ArrayList<Integer>();
		for(String i : ans){
			if(i.length() > 0){
				q.add(Integer.parseInt(i));
			}
		}
		
		return q;
	}

	
	
	
	}
	
	
	


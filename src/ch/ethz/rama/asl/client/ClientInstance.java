package ch.ethz.rama.asl.client;

import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

// Client make an instance of this in a thread
// 
// TODO add exception for adding msg to non existing queues

public class ClientInstance implements Runnable {
	public ClientInstance(int id){
		// get info from property file
		this.serverhost = "localhost";
		this.serverport = 4444;
		this.buffersize = 200;
		this.clientid = id;
		try {
			this.clientapi = new ClientCore(this.serverhost,this.serverport, buffersize);
			//once instantiated, register the client
			//addClient(this.clientid);
		} catch (IOException e) {
			// TODO Auto;generated catch block
			e.printStackTrace();
		}
		
	}
	public int clientid;
	ClientCore clientapi;
	Thread thread;
	int buffersize;
	String serverhost;
	int serverport;
	
	public int addQueue(String name){
		ResponseHandler handler = new ResponseHandler();
		String msg = ClientEncoder.eAddQueue(clientid, name);
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
		System.out.println(ans);
		return ans;
	}
	
	public int addClient(int clientid){
		ResponseHandler handler = new ResponseHandler();
		String msg = ClientEncoder.eAddClient(clientid);
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
		int ans = Integer.parseInt(answer[1]);
		System.out.println(ans);
		return ans;
	}
	public int deleteQueue(int clientid, int queueid){
		ResponseHandler handler = new ResponseHandler();
		String msg = ClientEncoder.eDeleteQueue(clientid,queueid);
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
		System.out.println(ans);
		return ans;
	}
	
	public int sendMessage(int queueid,int senderid, int receiverid, String msg1){
		ResponseHandler handler = new ResponseHandler();
		String msg = ClientEncoder.eSendMessage(queueid,senderid,receiverid,msg1);
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
		System.out.println(ans);
		return ans;
	}
	
	public String retreiveLatestMessage(int queueid, int receiverid){
		ResponseHandler handler = new ResponseHandler();
		String msg = ClientEncoder.eRetrieveLatestMessage(queueid, receiverid);
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
		String ans = (answer[1]);
		System.out.println(ans);
		return ans;
	}
	
	public String retreiveLatestMessageDelete(int queueid, int receiverid){
		ResponseHandler handler = new ResponseHandler();
		String msg = ClientEncoder.eRetrieveLatestMessageDelete(queueid, receiverid);
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
		String ans = (answer[1]);
		System.out.println(ans);
		return ans;
	}
	
	public String retreiveMessageFromSender(int queueid, int receiverid,int senderid){
		ResponseHandler handler = new ResponseHandler();
		String msg = ClientEncoder.eRetrieveMessageFromSender(queueid, receiverid,senderid);
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
		String ans = (answer[1]);
		System.out.println(ans);
		return ans;
	}
	
	public String retreiveMessageFromSenderDelete(int queueid, int receiverid,int senderid){
		ResponseHandler handler = new ResponseHandler();
		String msg = ClientEncoder.eRetrieveMessageFromSenderDelete(queueid, receiverid,senderid);
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
		String ans = (answer[1]);
		System.out.println(ans);
		return ans;
	}
	
	public List<Integer> queuesWithMessage(int clientid){
		ResponseHandler handler = new ResponseHandler();
		String msg = ClientEncoder.eQueuesWithMessages(clientid);
		// msg = QUEUESWITHMSG;clientid;???
		// response = QUEUESWITHMSG;
		try {
			clientapi.send(msg.getBytes(), handler);
		} catch (IOException e) {
			// TODO Auto;generated catch block
			e.printStackTrace();
		}
		String response = handler.waitForResponse();
		String[] answer = response.split(";");
		String[] ans = answer[1].split("&");
		List<Integer> q = new ArrayList<Integer>();
		for(String i : ans){
			if(i.length() > 0){
				q.add(Integer.parseInt(i));
			}
		}
		
		return q;
	}

	@Override
	public void run() {
		// TODO Auto-generated method stub
		
		
	}
	
	
	}
	
	
	


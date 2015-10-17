package ch.ethz.rama.asl.client;

import java.io.FileInputStream;
import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

// Client make an instance of this in a thread
// 
// TODO add exception for adding msg to non existing queues

public class ClientInstance {
	public ClientInstance(int id){
		// get info from property file
		String sp = "properties/client.properties";
		Properties p = new Properties();
		try{
			p.load(new FileInputStream(sp));
			this.serverhost = p.getProperty("Serverhost");
			this.serverport = Integer.parseInt(p.getProperty("Serverport"));
			this.buffersize = Integer.parseInt(p.getProperty("Clientmessagesize"));
			//this.clientid = id;
		
			this.clientapi = new ClientCore(this.serverhost,this.serverport, buffersize);
			//once instantiated, register the client
			this.clientid = addClient(this.clientid);
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
	
	public int addQueue(String name){
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
		System.out.println(response);
		return ans;
	}
	
	public int addClient(int clientid){
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
		int ans = Integer.parseInt(answer[1]);
//		System.out.println(ans);
		return ans;
	}
	public int deleteQueue(int clientid, int queueid){
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
		System.out.println(response);
		
		//		System.out.println(ans);
		return ans;
	}
	
	public int sendMessage(int queueid,int senderid, int receiverid, String msg1){
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
		System.out.println(response);
//		System.out.println(ans);
		return ans;
	}
	
	public String retreiveLatestMessage(int queueid, int receiverid){
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
		String ans = (answer[1]);
		System.out.println(response);
//		System.out.println(ans);
		return ans;
	}
	
	public String retreiveLatestMessageDelete(int queueid, int receiverid){
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
		System.out.println(response);
		String ans = (answer[1]);
//		System.out.println(ans);
		return ans;
	}
	
	public String retreiveMessageFromSender(int queueid, int receiverid,int senderid){
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
		String ans = (answer[1]);
		System.out.println(response);
//		System.out.println(ans);
		return ans;
	}
	
	public String retreiveMessageFromSenderDelete(int queueid, int receiverid,int senderid){
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
		System.out.println(response);
		String ans = (answer[1]);
//		System.out.println(ans);
		return ans;
	}
	
	public List<Integer> queuesWithMessage(int clientid){
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
		String[] ans = answer[1].split("&");
//		System.out.println(ans);
		System.out.println(response);
		List<Integer> q = new ArrayList<Integer>();
		for(String i : ans){
			if(i.length() > 0){
				q.add(Integer.parseInt(i));
			}
		}
		
		return q;
	}

	
	
	
	}
	
	
	


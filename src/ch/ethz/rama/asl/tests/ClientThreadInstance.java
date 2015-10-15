package ch.ethz.rama.asl.tests;

import java.util.List;
import java.util.Random;
import java.util.logging.Logger;

import ch.ethz.rama.asl.client.ClientInstance;
import ch.ethz.rama.asl.logging.MyLogger;

public class ClientThreadInstance implements Runnable{
	public final static Logger clientlogger = MyLogger.classLogger(ClientThreadInstance.class.getName(),"client-instance");
	int client_id;
	int number_queues;
	int number_clients;
	int duration;
	
	int msg_size;
	String msg_sample;
	ClientThreadInstance(int client_id,int number_queues,int number_clients,int duration,int msg_size){
		this.client_id = client_id;
		this.duration = duration;
		this.number_clients = number_clients;
		this.number_queues = number_queues;
		
		if(msg_size == 200){
			this.msg_size = 200;
			this.msg_sample = "meow200";
		}
		else
		{
			this.msg_sample="meow2000";
			this.msg_size = 2000;
		}
	}
	@Override
	public void run() {
		// TODO Auto-generated method stub
		clientlogger.info("Client with id ::"+client_id);
		ClientInstance client = new ClientInstance(client_id);
		Random magic = new Random();
		
		long starttime = System.currentTimeMillis();
		long endTime = starttime + (duration*1000);
		clientlogger.info("starttime::"+starttime+" client_id::"+client_id);
		
		int iterations = 0;
		while(System.currentTimeMillis() < endTime)
		{
			//send message
			int random_client = magic.nextInt(number_clients)+1;
			int random_queue = magic.nextInt(number_queues)+1; 
			long startrequestTime = System.currentTimeMillis();
			int msgid = client.sendMessage(random_queue, client_id, random_client, msg_sample);
			long endrequestTime = System.currentTimeMillis();
			
			//get queues with all messages
			int queue = 0;
			// do this until we get at least 1 queue
			while(queue == 0 && (System.currentTimeMillis() < endTime)){
				startrequestTime = System.currentTimeMillis();
				List<Integer> list_queues = client.queuesWithMessage(client_id);
				endrequestTime = System.currentTimeMillis();
				
			}
			
			//obtain recent msg from that queue
			startrequestTime = System.currentTimeMillis();
			String msg = client.retreiveLatestMessageDelete(queue, client_id);
			endrequestTime =System.currentTimeMillis();
			
			// count number of time client
			// will send,get queues and receive&del msgs
			iterations++;
			
		}
		
		
	}
}

package ch.ethz.rama.asl.tests;

import java.io.IOException;
import java.util.List;
import java.util.Random;
import java.util.concurrent.TimeUnit;
import java.util.logging.Handler;
import java.util.logging.Logger;

import ch.ethz.rama.asl.client.ClientInstance;
import ch.ethz.rama.asl.exceptions.GaneshaQueueException;
import ch.ethz.rama.asl.logging.BufferingHandler;
import ch.ethz.rama.asl.logging.MyLogger;

public class ClientThreadInstance2 implements Runnable {
	
	public final static Logger clientlogger = MyLogger.classLogger(ClientThreadInstance.class.getName(),"client-instance");
	int client_id;
	int number_queues;
	int number_clients;
	int duration;
	int number_machines;
	int msg_size;
	String msg_sample;
	int number_of_clients_in_system;
	int number_of_queues_in_system;
	static int machine_id; // machine that generated this client
	ClientThreadInstance2(int machine_id,int client_id,int number_queues,int number_clients,int duration,int msg_size,int number_machines){
		this.client_id = client_id;
		this.duration = duration;
		this.number_clients = number_clients;
		this.number_queues = number_queues;
		this.number_machines = number_machines;
		this.number_of_clients_in_system = number_clients*number_machines;
		//this.number_of_queues_in_system = number_queues*number_machines;
		this.machine_id = machine_id;
		
		if(msg_size == 200){
			// message of length 200
			this.msg_size = 200;
			this.msg_sample = "A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c";
		}
		else
		{
			// message of length 2000
			this.msg_sample="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";
			this.msg_size = 2000;
		}
	}
	String preName = "client-instance";
	String file_path = "/Users/ramapriyasridharan/Documents/asl_v1/"+preName+machine_id+".log";
	
	@Override
	public void run() {
		
		ClientInstance client = null;
		try {
			client = new ClientInstance(client_id);
		} catch (Exception e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}
		
		// RANDOM GENERATOR!!!!!
		Random magic = new Random();
		
		long starttime = System.currentTimeMillis();
		long endTime = starttime + (duration*1000);
		//clientlogger.info("starttime:: "+starttime+" client_id::"+client_id);
		
		int iterations = 0;
		while(System.currentTimeMillis() < endTime)
		{
			
			
			//send message
			int random_client = magic.nextInt(number_of_clients_in_system)+1;
			int random_queue = magic.nextInt(number_queues)+1;
			long endrequestTime;
			long startrequestTime = System.currentTimeMillis();
			
			/*try {
				int msgid = client.sendMessage(random_queue, client_id, random_client, msg_sample);
			} catch (GaneshaQueueException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			endrequestTime = System.currentTimeMillis();
			//clientlogger.info("SEND_MSG :: "+(endrequestTime-startrequestTime));
			clientlogger.info("SEND_MSG,"+(endrequestTime-startrequestTime));
			
			int randomclient = magic.nextInt(number_of_clients_in_system)+1;
			int randomqueue = magic.nextInt(number_queues)+1; 
			startrequestTime = System.currentTimeMillis();
			
			try {
				int msgid = client.sendMessage(randomqueue, client_id, randomclient, msg_sample);
			} catch (GaneshaQueueException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			endrequestTime = System.currentTimeMillis();
			//clientlogger.info("SEND_MSG :: "+(endrequestTime-startrequestTime));
			clientlogger.info("SEND_MSG,"+(endrequestTime-startrequestTime));*/
			
			
			
			
			
			
			
			
			
			//get queues with all messages
			int queue = -6;
			// do this until we get at least 1 queue
			// POLL until a queue with message is found
			while(queue < 0 && (System.currentTimeMillis() < endTime)){
				startrequestTime = System.currentTimeMillis();
				List<Integer> list_queues = null;
				try {
					list_queues = client.queuesWithMessage(client_id);
				} catch (GaneshaQueueException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
				endrequestTime = System.currentTimeMillis();
				clientlogger.info("GET_QUEUE,"+(endrequestTime-startrequestTime));
				if (list_queues.size() > 0){
				queue = list_queues.get(0);
				}
				
			}
			
			
			
			
			
			
			
			
			
			
			
			
			//obtain recent msg from that queue
			/*startrequestTime = System.currentTimeMillis();
			String msg = null;
			try {
				msg = client.retreiveLatestMessageDelete(queue, client_id);
			} catch (GaneshaQueueException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			endrequestTime = System.currentTimeMillis();
			//assert(msg.length() == msg_size);
			
			clientlogger.info("GET_LATEST_MSG_DELETE,"+(endrequestTime-startrequestTime));
			
			// count number of time client
			// will send,get queues and receive&del msgs
			iterations++;
			*/
		}//end while
		
//		handler.close();
		
		
		
	}
}

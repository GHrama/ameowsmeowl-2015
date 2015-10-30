package ch.ethz.rama.asl.tests;

import java.util.List;

import ch.ethz.rama.asl.client.ClientInstance;
import ch.ethz.rama.asl.exceptions.GaneshaQueueException;

public class TestNoQueue {
public static void main(String arg[]) throws Exception{
		
		// instead of registering client on the go
		// lets make sure that we create the rows first
		
		ClientInstance v = new ClientInstance(50);//id 1
		// create 4 queues and store their ids
		
		int q1 = v.addQueue("q1");
		int q2 = v.addQueue("q1");
		int q3 = v.addQueue("q1");
		
		
		// delete non existing queue
		// executed? or not
		//ßv.retreiveMessageFromSender(200, v.clientid, v.clientid);
		
		v.deleteQueue(v.clientid,q1);
		v.sendMessage(q2, v.clientid, v.clientid, "null");
		v.retreiveMessageFromSender(q2, v.clientid, v.clientid);
		v.retreiveMessageFromSenderDelete(q2, v.clientid, v.clientid);
		v.retreiveLatestMessage(q2, v.clientid);
		
		
		
		
		
		
		
	
		
		

		
		
		
		
		}
}

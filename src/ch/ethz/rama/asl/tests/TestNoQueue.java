package ch.ethz.rama.asl.tests;

import java.util.List;

import ch.ethz.rama.asl.client.ClientInstance;

public class TestNoQueue {
public static void main(String arg[]){
		
		// instead of registering client on the go
		// lets make sure that we create the rows first
		
		ClientInstance v = new ClientInstance(1);//id 1
		// create 4 queues and store their ids
		
		int q1 = v.addQueue("q1");
		int q2 = v.addQueue("q1");
		int q3 = v.addQueue("q1");
		
		// get message from queue 4 does not exist
		// client gets no expetion but a null
		String msg = v.retreiveLatestMessage(-100, v.clientid);
		
		// no message but queues exists
		// get null-OK
		String msg1 = v.retreiveLatestMessage(q1, v.clientid);
		
		// no message but queue exists
		// get null-OK
		String msg2 = v.retreiveLatestMessage(q2, v.clientid);
		
		
		// send message to existing queue to non existing  client
		// getting -ve number
		v.sendMessage(q3, v.clientid,17, "moo");
		
		
		// send message to a non existing queue from and to existing client
		// gives a +ve msg id
		v.sendMessage(7, v.clientid,v.clientid, "moo");
		
		System.out.println(msg);
		System.out.println(msg1);
		System.out.println(msg2);
		
		
		
		
		
		
		
		
	
		
		

		
		
		
		
		}
}

package ch.ethz.rama.asl.tests;

import java.io.IOException;
import ch.ethz.rama.*;
import java.nio.ByteBuffer;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;

import ch.ethz.rama.asl.client.*;;


public class DummyTest {
	
	public static void main(String arg[]){
		
		// instead of registering client on the go
		// lets make sure that we create the rows first
		
		ClientInstance v = new ClientInstance(1);//id 1
		ClientInstance v1 = new ClientInstance(2);//id 2
		// create 4 queues and store their ids
		
		int q1 = v.addQueue("q1");
		int q2 = v1.addQueue("q2");
		int q3 = v1.addQueue("q3");
		int q4 = v.addQueue("q4");
		
		System.out.println("client 1 id ="+v.clientid);
		System.out.println("client 2 id ="+v1.clientid);
		
		int msg1id = v.sendMessage(q1, v.clientid, v1.clientid, "first message");
		int msg3id = v.sendMessage(q2, v.clientid, -1, "3rd message");
		int msg2id = v.sendMessage(q2, v.clientid, v1.clientid, "second message");
		
		
		v.retreiveLatestMessageDelete(q1, v.clientid);
		v1.retreiveLatestMessageDelete(q2, v1.clientid);
		v.retreiveLatestMessageDelete(q2, v.clientid);
		
		
		
		
		
	
		
		

		
		
		
		
		}
		
		
		
		
		
		
		
	

}

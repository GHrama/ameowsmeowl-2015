package ch.ethz.rama.asl.tests;

import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

import ch.ethz.rama.asl.client.ClientInstance;
import ch.ethz.rama.asl.logging.MyLogger;

public class MakeClientsClass {
	
	public final static Logger logger = MyLogger.classLogger(MakeClientsClass.class.getName(),"clients");
	
	public static void main(String args[]) throws InterruptedException{
		
		
		logger.info("Beginning experiment");
//		 take arguments from command line args(script/ant)
		int machine_id = Integer.parseInt(args[0]);
		int number_machines = Integer.parseInt(args[1]);
		int number_queues = Integer.parseInt(args[2]);
		int number_clients = Integer.parseInt(args[3]);
		int duration_experiment = Integer.parseInt(args[4]);
		int message_length = Integer.parseInt(args[5]);
		
//		int machine_id = 1;
//		int number_machines = 1;
//		int number_queues = 5;
//		int number_clients = 5;
//		int duration_experiment = 20;
//		int message_length = 200;
		logger.info("machine_id ::"+machine_id);
		logger.info("No of machines ::"+number_machines);
		logger.info("No of queues ::"+number_queues);
		logger.info("No of clients ::"+number_clients);
		logger.info("Duration of experiement ::"+duration_experiment);
		logger.info("Length of message ::"+message_length);
		// instance used to create clients and queues
		ClientInstance dummy_instance = new ClientInstance(9999);
		// create number_queues/number_machines queues
		// Choose numbers carefully
		for(int i=0;i<number_queues/number_machines;i++){
			String queue_name="queue::"+i+1+" of machine::"+machine_id;
			int q1 = dummy_instance.addQueue(queue_name);
			logger.info("Created queue id ::"+q1+" From machine ::"+machine_id+" Local queue no ::"+i);
			System.out.println("created queue::"+i+" machine:"+machine_id+" DB queue number::"+q1);
			
		}
		
		// wait till all queues have been created on all machines
		Thread.sleep(1000);
		// Now we need to create the client threads
		// create clients before
		List<Thread> clientThreadArray = new ArrayList<Thread>();
		for(int i=0; i<number_clients;i++){
			//numberof clients assigned to this machine =
			// make sure numbers are divisible
			//int assignment_number = number_clients/number_machines;
			// the client ids are i*number_machine
			ClientThreadInstance c1 = new ClientThreadInstance((i+1)*number_machines,number_queues,number_clients,duration_experiment,message_length);
			Thread c1thread = new Thread(c1);
			clientThreadArray.add(c1thread);
			c1thread.start();
			
		}
		
		//after execution
		for(Thread in : clientThreadArray){
			in.join();
			}
		
		System.out.println("all cient threads joined in machine id::"+machine_id);
		logger.info("machine_id ::"+machine_id+" client execution terminated");

	}

}

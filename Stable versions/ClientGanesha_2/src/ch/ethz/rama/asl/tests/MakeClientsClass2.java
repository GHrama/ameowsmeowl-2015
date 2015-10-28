package ch.ethz.rama.asl.tests;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.logging.Handler;
import java.util.logging.Logger;

import ch.ethz.rama.asl.client.ClientInstance;
import ch.ethz.rama.asl.exceptions.GaneshaQueueException;
import ch.ethz.rama.asl.logging.BufferingHandler;
import ch.ethz.rama.asl.logging.MyLogger;

public class MakeClientsClass2 {
	
	
	public final static Logger logger = MyLogger.classLogger(MakeClientsClass.class.getName(),"clients");
	
	public static void main(String args[]) throws Exception{
		
		
		 
		

		logger.info("Beginning experiment");
		
//		take arguments from command line args(script/ant)
		int machine_id = Integer.parseInt(args[0]);
		int number_machines = Integer.parseInt(args[1]);
		int number_queues = Integer.parseInt(args[2]);
		int number_clients_full = Integer.parseInt(args[3]);
		int duration_experiment = Integer.parseInt(args[4]);
		int message_length = Integer.parseInt(args[5]);
		
		
		// 400 clients and queues pre assigned
//		int machine_id = 1;
//		int number_machines = 1;
//		int number_queues = 5;
//		int number_clients_full = 30; // number fo clients per machine
//		int duration_experiment = 10;
//		int message_length = 200;
		int number_clients = number_clients_full/number_machines;
//		String preName = "clients";
//		String file_path = "/Users/ramapriyasridharan/Documents/asl_v1/"+preName+machine_id+".log";
//		Handler handler = new BufferingHandler(file_path, 1, TimeUnit.SECONDS); 
//		logger.addHandler(handler);
//		logger.info("machine_id ::"+machine_id);
//		logger.info("No of machines ::"+number_machines);
//		logger.info("No of queues ::"+number_queues);
//		logger.info("No of clients ::"+number_clients);
//		logger.info("Duration of experiement ::"+duration_experiment);
//		logger.info("Length of message ::"+message_length);
//		logger.info("Machine id = "+machine_id);
		// instance used to create clients and queues
		
		// create number_queues/number_machines queues
		// Choose numbers carefully
		
		
		// wait till all queues have been created on all machines
		Thread.sleep(1000);
		// Now we need to create the client threads
		// create clients before
		List<Thread> clientThreadArray = new ArrayList<Thread>();
		for(int i=0; i < number_clients; i++){
			//number of clients assigned to this machine =
			// make sure numbers are divisible
			//int assignment_number = number_clients/number_machines;
			// the client ids are i*number_machine
			//logger.info("Creating new CLIENT_THREAD :: "+(i+1)+"in machine id :: "+machine_id);
			// client id = ((i+1)+((number_machines-1)*number_clients)))
			// current_id + number of othuer machine clients
			//logger.info("Client number = "+((i+1)+((machine_id-1)*number_clients)));
			int cc = ((i+1)+((machine_id-1)*number_clients));
			ClientThreadInstance2 c1 = new ClientThreadInstance2(machine_id,cc,number_queues,number_clients,duration_experiment,message_length,number_machines);
			Thread c1thread = new Thread(c1);
			clientThreadArray.add(c1thread);
			c1thread.start();
			
		}
		
		//after execution
		for(Thread in : clientThreadArray){
			in.join();
			}
		
		//System.out.println("all cient threads joined in machine id::"+machine_id);
		//logger.info("machine_id :: "+machine_id+" client execution terminated");
//		handler.close();

	}
	

}

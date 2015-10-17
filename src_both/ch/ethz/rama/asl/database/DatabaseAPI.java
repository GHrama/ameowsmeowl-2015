package ch.ethz.rama.asl.database;



import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

import org.postgresql.ds.PGPoolingDataSource;

// adapted from https://jdbc.postgresql.org/documentation/head/ds-ds.html
// http://tutorials.jenkov.com/java-nio/overview.html




public class DatabaseAPI {
	public DatabaseAPI(){
		
	}
	
	
	// adds new queue
	// returns id of queue created
	// TESTED OK
	public int addNewQueue(Connection conn, String name) {
		Statement stmt = null;
		ResultSet result = null;
		//call procedure
		String q = String.format("SELECT add_new_queue('%s')", name);
		int queueID = -1;

		try {
			stmt = conn.createStatement();
			//	measure start and end of query execution
			//	helps optimize the indexes!!!
			long start = System.currentTimeMillis();
			//execute query
			result = stmt.executeQuery(q);
			long end = System.currentTimeMillis();

			
			// get ID of newly created queue
			if (result.next()) {
				queueID = result.getInt(1);
			}

			// Only one result should be returned. If not, something's horribly
			// messed up
			// Jquery?
			//assert (!result.next());

		} catch (SQLException e) {
			e.printStackTrace();
		}

		return queueID;
	}
	
	//register client
	public int addClient(Connection conn, String name) {
		Statement stmt = null;
		ResultSet result = null;
		//call procedure
		String q = String.format("SELECT add_client('%s')", name);
		int clientID = -1;

		try {
			stmt = conn.createStatement();
			//	measure start and end of query execution
			//	helps optimize the indexes!!!
			long start = System.currentTimeMillis();
			//execute query
			result = stmt.executeQuery(q);
			long end = System.currentTimeMillis();

			
			// get ID of newly created queue
			if (result.next()) {
				clientID = result.getInt(1);
			}

			// Only one result should be returned. If not, something's horribly
			// messed up
			// Jquery?
			//assert (!result.next());

		} catch (SQLException e) {
			e.printStackTrace();
		}

		return clientID;
	}
	
	// deletes the queue
	// returns 1 if done successfully
	// 0 if not
	// TESTED OK
	public int deleteQueue(Connection conn, int queue_number){
		Statement stmt = null;
		ResultSet result = null;
		int executed = 0;
		//call procedure
		String q = String.format("SELECT delete_queue('%d')", queue_number);
		try{
			stmt = conn.createStatement();
			long start = System.currentTimeMillis();
			result = stmt.executeQuery(q);
			long end = System.currentTimeMillis();
			if(result.next()){
				executed = 1;
			}
			} catch(SQLException e){
				e.printStackTrace();
			}
		return executed ; // did it execute fine?
	}
	
	//delete
	public int deleteClient(Connection conn, int client_number){
		Statement stmt = null;
		ResultSet result = null;
		int executed = 0;
		//call procedure
		String q = String.format("SELECT delete_client('%d')", client_number);
		try{
			stmt = conn.createStatement();
			long start = System.currentTimeMillis();
			result = stmt.executeQuery(q);
			long end = System.currentTimeMillis();
			if(result.next()){
				executed = 1;
			}
			} catch(SQLException e){
				e.printStackTrace();
			}
		return executed ; // did it execute fine?
	}
	
	
	// adds message
	// get message id entered
	public int addMesssage(Connection conn, int queue_number, int sender_id, int receiver_id, String payload){
		Statement stmt = null;
		ResultSet result = null;
		int id = -6;
		String q = String.format("SELECT add_message('%d','%d','%d','%s')", queue_number,sender_id,receiver_id,payload);
		try{
			stmt = conn.createStatement();
			long start = System.currentTimeMillis();
			result = stmt.executeQuery(q);
			long end = System.currentTimeMillis();
			
			if(result.next()){
				id = result.getInt(1);
				// get message id that is entered
			}
			
		}catch(SQLException e){
			e.printStackTrace();
		}
		return id;
		// if -6 hasnt returned anything
	}
	
	// get the latest message
	// returns latest message (payload)
	public String getLatestMessage(Connection conn, int queue_number, int receiver_id){
		Statement stmt = null;
		ResultSet result = null;
		String answer = null;
		// add * for select statements !!
		String q = String.format("SELECT * FROM get_latest_message('%d','%d')", queue_number,receiver_id);
		try{
			stmt = conn.createStatement();
			long start = System.currentTimeMillis();
			result = stmt.executeQuery(q);
			long end = System.currentTimeMillis();
			
			if(result.next()){
				// add testing 
				// check if queue is actually the one asked for
				// check receiver
				// check if 1 answer only retrieved (latest msg can only be 1 right??)
				answer = result.getString(4); //payload
			}
			
		}catch(SQLException e){
			e.printStackTrace();
		}
		return answer;
	}
	
	// get latest message
	// delete the message
	//  return message payload
	public String getLatestMessageDelete(Connection conn, int queue_number, int receiver_id){
		Statement stmt = null;
		ResultSet result = null;
		String answer = null;
		// add * for select statements !!
		String q = String.format("SELECT * FROM get_latest_message_delete('%d','%d')", queue_number,receiver_id);
		try{
			stmt = conn.createStatement();
			long start = System.currentTimeMillis();
			result = stmt.executeQuery(q);
			long end = System.currentTimeMillis();
			
			if(result.next()){
				// add testing 
				// check if queue is actually the one asked for
				// check receiver
				// check if 1 answer only retrieved (latest msg can only be 1 right??)
				answer = result.getString(4); //payload
			}
			
		}catch(SQLException e){
			e.printStackTrace();
		}
		return answer;
	}
	
	// get all queues that have messages for a particular client
	// return the queue numbers in an arraylist
	public List<Integer> getQueuesWithMessage(Connection conn,int receiver_id){
		List<Integer> queue_numbers = new ArrayList<Integer>();
		Statement stmt = null;
		ResultSet result = null;
		String answer = null;
		// add * for select statements !!
		String q = String.format("SELECT get_queues_with_messages('%d')", receiver_id);
		//check statements!!
		try{
			stmt = conn.createStatement();
			long start = System.currentTimeMillis();
			result = stmt.executeQuery(q);
			long end = System.currentTimeMillis();
//			if(result == null)
//				queue_numbers.add(-10000);
//			else
			while(result.next()){
				// add testing 
				// check if queue is actually the one asked for
				// check receiver
				// check if 1 answer only retrieved (latest msg can only be 1 right??)
				queue_numbers.add(result.getInt(1)); //payload
			}
			
		}catch(SQLException e){
			e.printStackTrace();
		}
		return queue_numbers;
	}
	
	
	// get the latest message from a particular sender
	// ie client check if a particular sender sent it a message
	// if so return the payload
	public String latestMessageFromSender(Connection conn,int queue_number, int sender,int receiver_id){
		ArrayList<Integer> queue_numbers = null;
		Statement stmt = null;
		ResultSet result = null;
		String answer = null;
		// add * for select statements !!
		String q = String.format("SELECT latest_message_from_sender('%d')", receiver_id);
		try{
			stmt = conn.createStatement();
			long start = System.currentTimeMillis();
			result = stmt.executeQuery(q);
			long end = System.currentTimeMillis();
			
			while(result.next()){
				// add testing 
				// check if queue is actually the one asked for
				// check receiver
				// check if 1 answer only retrieved (latest msg can only be 1 right??)
				answer = result.getString(4); //payload
			}
			
		}catch(SQLException e){
			e.printStackTrace();
		}
		return answer;
	}
	
	
	// get Latest message from sender and delete
	// client asks queue for message from a particular sender
	// returns payload if message present
	public String latestMessageFromSenderDelete(Connection conn,int queue_number, int sender,int receiver_id){
		ArrayList<Integer> queue_numbers = null;
		Statement stmt = null;
		ResultSet result = null;
		String answer = null;
		// add * for select statements !!
		String q = String.format("SELECT latest_message_from_sender_delete('%d')", receiver_id);
		try{
			stmt = conn.createStatement();
			long start = System.currentTimeMillis();
			result = stmt.executeQuery(q);
			long end = System.currentTimeMillis();
			
			while(result.next()){
				// add testing 
				// check if queue is actually the one asked for
				// check receiver
				// check if 1 answer only retrieved (latest msg can only be 1 right??)
				answer = result.getString(4); //payload
			}
			
		}catch(SQLException e){
			e.printStackTrace();
		}
		return answer;
	}
	
	public static void main (String args[]){
		
		
		//adapted from postgres website
		// name of thread pool
		PGPoolingDataSource source = new PGPoolingDataSource();
		source.setDataSourceName("db-connection-pooling");
		source.setServerName("localhost");
		source.setDatabaseName("message");
		source.setUser("ramapriyasridharan");
		source.setPassword("");
		source.setMaxConnections(1);
		
		Connection conn = null;
		try
		{
		    
		    // use connection
		    //make some calls to some DBAPI methods
		    DatabaseAPI dbapi = new DatabaseAPI(); 
		    conn = source.getConnection();
		    
		    // add q1 & q2
		    //this is for broadcast
		    /*int cneg1 = dbapi.addClient(conn, "clientneg1");
		    int c50 = dbapi.addClient(conn, "client50");
		    int c60 = dbapi.addClient(conn, "client60");
		    int c70 = dbapi.addClient(conn, "client70");*/
		    
		    int q1 = dbapi.addNewQueue(conn, "q1");
			System.out.println("Created queue q1 with ID: " + q1);
			int q2 = dbapi.addNewQueue(conn, "q2");
			System.out.println("Created queue q2 with ID: " + q2);

			// Delete queue q2
			System.out.println("Deleting queue q1: "
					+ dbapi.deleteQueue(conn, q1));                

			// Add message, conn, queue, sender,retreiver
			int q2msg1 = dbapi.addMesssage(conn, q2, 2, 3, "q21msg1");
			System.out.println("Added message with ID: " + q2msg1);
			int q2msg2 = dbapi.addMesssage(conn, q2, 2, 1, "q21msg2");
			System.out.println("Added message with ID: " + q2msg2);
			int q2msg3 = dbapi.addMesssage(conn, q2, 2, 4, "q21msg3");
			System.out.println("Added message with ID: " + q2msg3);
			int q2msg4 = dbapi.addMesssage(conn, q2, 3, 1, "q21msg4");
			System.out.println("Added message with ID: " + q2msg4);

			// Queues with messages,conn,receiver
			System.out.println(dbapi.getQueuesWithMessage(conn,
					2));

			// Check if messages have been added,from q2 for client 70
			System.out.println(dbapi.getLatestMessage(conn, q2, 3)); // Should return q21msg3
			// returns null
			System.out.println(dbapi.getLatestMessage(
					conn, q2, 3)); // Should return q21msg2
		    
		}
		catch (SQLException e)
		{
			e.printStackTrace();
		}
		finally
		{
		    if (conn != null)
		    {
		        try { conn.close(); } 
		        catch (SQLException e) {
		        	e.printStackTrace();
		        }
		    }
		}
		
	}
}


package ch.ethz.rama.asl.pool;

import java.sql.*;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;

public class ConnectionPool {
	
	// holds all connections
	private BlockingQueue<Connection> pool;
	
	private int maxPoolSize;
	private int initialPoolSize;
	private int currentPoolSize;
	
	// db url,use and password
	private String dbUrl;
	private String dbUser;
	private String dbPassword;
	
	//  get driverClassName
	public ConnectionPool(int maxPoolSize, int initialPoolSize, String url, String user, 
			String password, String driverClassName) throws ClassNotFoundException, SQLException{
		this.maxPoolSize = maxPoolSize;
		this.initialPoolSize = initialPoolSize;
		
		this.dbUrl = url;
		this.dbUser = user;
		this.dbPassword = password;
		
		// initialize pool with maximum size
		// true for fifo order
		this.pool = new ArrayBlockingQueue<Connection>(maxPoolSize, true);
		
		initPool(driverClassName);
	}
	
	// initialize pool with specified anount of initial threads
	private void initPool(String driverClassName) throws ClassNotFoundException, SQLException{
		Class.forName(driverClassName);
		
		// open connections
		for(int i = 0; i < initialPoolSize; i++){
			// open connections as long as number of connections lesser than max connections
			// 
			openConnection();
		}
	}
	
	private synchronized void openConnection() throws SQLException{
		if(currentPoolSize >= maxPoolSize){ 
			return; 
		}
		// open a conn
		Connection conn = DriverManager.getConnection(dbUrl,dbUser,dbPassword);
		// see if can insert new connection into pool blocking queue
		if(pool.offer(conn)){
			currentPoolSize++;
		}
	}
	
	// pop from queue if connection available
	public Connection borrowConnection() throws InterruptedException, SQLException{
		// in no connections and connections can be opened?
		if(pool.isEmpty() && currentPoolSize < maxPoolSize){
			openConnection();
		}
		// else just wait until a connection is returned
		// wait until connection becomes available
		Connection c = pool.take();
		return c;
	}
	// give connection back
	public void returnConnection(Connection conn){
		if(conn != null){
			pool.offer(conn);
		}
	}
}

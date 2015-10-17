package ch.ethz.rama.asl.pool;
// http://www.codeproject.com/Articles/710384/Creating-a-custom-database-connection-pool
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
	public ConnectionPool(int maxPoolSize, String url, String user, 
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
		for(int i = 0; i < maxPoolSize; i++){
			Connection conn = DriverManager.getConnection(dbUrl,dbUser,dbPassword);
			// add to pool
			pool.offer(conn);
		}
	}
	
//	private synchronized void openConnection() throws SQLException{
//		if(currentPoolSize >= maxPoolSize){ 
//			return; 
//		}
//		// open a conn
//		Connection conn = DriverManager.getConnection(dbUrl,dbUser,dbPassword);
//		// see if can insert new connection into pool blocking queue
//		if(pool.offer(conn)){
//			currentPoolSize++;
//		}
//	}
	
	// pop from queue if connection available
	public Connection borrowConnection() throws InterruptedException, SQLException{
		// in no connections and connections can be opened?
		Connection c = null;
		// else just wait until a connection is returned
		// wait until connection becomes available
		c = pool.take();
		// if conn null or not valid
		if(c == null|| !c.isValid(2))
		{
			if(c != null){
				try{
					c.close();
				}catch(SQLException e){
					e.printStackTrace();
				}
			}
			c = DriverManager.getConnection(dbUrl,dbUser,dbPassword);
		}
		return c;
	}
	// give connection back
	public void returnConnection(Connection conn){
		if(conn != null){
			pool.offer(conn);
		}
	}
	
	// make all connections = null
	public void closePool(){
		Connection conn = null;
		while((conn = pool.poll()) != null){
			try {
				conn.close();
			} catch (SQLException e) {
				System.err.println(e.getLocalizedMessage());
				e.printStackTrace();
			}
		}
	}
}

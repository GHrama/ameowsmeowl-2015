package ch.ethz.rama.asl.server;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.nio.ByteBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.logging.Logger;



import ch.ethz.rama.asl.pool.ConnectionPool;

//import org.postgresql.ds.PGConnectionPoolDataSource;
//import org.postgresql.ds.PGPoolingDataSource;

//import ch.ethz.asl.commons.ChangeRequest;
//import ch.ethz.asl.commons.logging.MessagingSystemLogger;

// adapted from http://rox-xmlrpc.sourceforge.net/niotut/

public class MessageServer implements Runnable {
	
	private final String host;
	private final int port;
	static String drivername = "org.postgresql.Driver";

	// TODO Read this from config.
	private final int BUFFER_SIZE;

	// Server NIO related variables
	ServerSocketChannel server = null;
	Selector selector = null;
	SelectionKey key;
	public boolean running;

	// The buffer into which we'll read data when it's available
	private ByteBuffer readBuffer;

	ExecutorService messageWorkerPool;
    ConnectionPool pool;

	// A list of PendingChange instances
	// changing the channel ops
	private List<ChangeRequest> pendingChanges = new LinkedList<ChangeRequest>();
	// Maps a SocketChannel to a list of ByteBuffer instances
	//thing that need to be written??
	private Map<SocketChannel, List<ByteBuffer>> pendingData = new HashMap<SocketChannel, List<ByteBuffer>>();
	
	// Create a pool of worker threads and pass them on to the server
	// also pass the dbconnpool
	// take buffersize from configuration
	// host and port for from config file too
	public MessageServer(ExecutorService messageWorkerPool,
			 String host, int port, int bufferSize, ConnectionPool pool)
			throws IOException {
		this.host = host;
		this.port = port;
		this.running = true;

		this.messageWorkerPool = messageWorkerPool;
		this.pool = pool;
		this.BUFFER_SIZE = bufferSize + 100;
		this.readBuffer = ByteBuffer.allocate(BUFFER_SIZE);

		server = ServerSocketChannel.open();
		// nonblocking I/O
		server.configureBlocking(false);
		// host-port
		server.socket().bind(new InetSocketAddress(this.port));
		// Create the selector
		selector = Selector.open();
		// Recording server to selector (type OP_ACCEPT)
		key = server.register(selector, SelectionKey.OP_ACCEPT);
	}

	
	@Override
	public void run() {
		while (running) {
			// Wait for an event one of the registered channels
			try {

				// Process any changes piled up
				synchronized (this.pendingChanges) {
					// pending changes stored the changes to be made
					// on each socket
					// change the socket to a write one
					Iterator<ChangeRequest> changes = this.pendingChanges
							.iterator();
					while (changes.hasNext()) {
						ChangeRequest change = (ChangeRequest) changes.next();
						switch (change.type) {
						case ChangeRequest.CHANGEOPS:
							SelectionKey key = change.socket
									.keyFor(this.selector);
							key.interestOps(change.ops);
						}
					}
					this.pendingChanges.clear();
				}
				// cleared all changes that were made
				// ie changes to sockets listening 
				
				
				// Wait for event on registered channels
				selector.select();

				// Get keys
				Set<SelectionKey> keys = selector.selectedKeys();
				Iterator<SelectionKey> keyIterator = keys.iterator();

				// For each keys
				while (keyIterator.hasNext()) {
					SelectionKey key = (SelectionKey) keyIterator.next();

					// Remove the current key
					keyIterator.remove();

					if (!key.isValid()) {
						continue;
					}

					if (key.isAcceptable()) {
						// Option 1 - Accept
						accept(key);
					} else if (key.isReadable()) {
						// Option 2 - Read request
						read(key);
					} else if (key.isWritable()) {
						// Option 3 - Write response
						write(key);
					}
				}
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}

	public void accept(SelectionKey key) throws IOException {
		// For an accept to be pending the channel must be a server socket
		// channel.
		ServerSocketChannel serverSocketChannel = (ServerSocketChannel) key
				.channel();

		// Accept the connection and make it non-blocking
		SocketChannel socketChannel = serverSocketChannel.accept();
		Socket socket = socketChannel.socket();
		socketChannel.configureBlocking(false);

		// Register the new SocketChannel with our Selector, indicating
		// we'd like to be notified when there's data waiting to be read
		socketChannel.register(this.selector, SelectionKey.OP_READ);
	}

	public void read(SelectionKey key) throws IOException {

		
		
		SocketChannel socketChannel = (SocketChannel) key.channel();
		
		// Clear out our read buffer so it's ready for new data
		this.readBuffer.clear();
		

		// Attempt to read off the channel
		int numRead;
		try {
			numRead = socketChannel.read(this.readBuffer);
			
			
		} catch (IOException e) {
			// The remote forcibly closed the connection, cancel
			// the selection key and close the channel.
			key.cancel();
			socketChannel.close();
			return;
		}
		// numread is the number of bytes in the buffer
		if (numRead == -1) {
			// Remote entity shut the socket down cleanly. Do the
			// same from our end and cancel the channel.
			key.channel().close();
			key.cancel();
			return;
		}

		// Hand the data off to the Message Worker
		// register time to wait and process the data starting now
		// throughput is measures using this response time,to avoid latency
		messageWorkerPool.execute(new MessageWorker(this.pool,this,socketChannel,this.readBuffer.array(), numRead, System.currentTimeMillis()));

	}

	public void write(SelectionKey key) throws IOException {

		SocketChannel socketChannel = (SocketChannel) key.channel();

		synchronized (this.pendingData) {
			List<ByteBuffer> queue = this.pendingData.get(socketChannel);

			// Write until there's not more data ...
			while (!queue.isEmpty()) {
				ByteBuffer buf = (ByteBuffer) queue.get(0);
				socketChannel.write(buf);
				if (buf.remaining() > 0) {
					// ... or the socket's buffer fills up
					break;
				}
				
				queue.remove(0);
			}

			if (queue.isEmpty()) {
				// We wrote away all data, so we're no longer interested
				// in writing on this socket. Switch back to waiting for
				// data.
				key.interestOps(SelectionKey.OP_READ);
			}
		}

		

	}

	public void send(SocketChannel socket, byte[] data) {
		synchronized (this.pendingChanges) {
			// Indicate we want the interest ops set changed

			
			long changeQueueArrivalTime = System.currentTimeMillis();
			this.pendingChanges.add(new ChangeRequest(socket,
					ChangeRequest.CHANGEOPS, SelectionKey.OP_WRITE,
					changeQueueArrivalTime));
			// And queue the data we want written
			synchronized (this.pendingData) {
				List<ByteBuffer> queue = this.pendingData.get(socket);
				if (queue == null) {
					queue = new ArrayList<ByteBuffer>();
					this.pendingData.put(socket, queue);
				}
				queue.add(ByteBuffer.wrap(data));
			}
		}

		// Finally, wake up our selecting thread so it can make the required
		// changes
		this.selector.wakeup();
	}

	public static void main(String[] args) throws IOException {
		
			String sp = "properties/middleware.properties";
//		    String sp = "/Users/ramapriyasridharan/Documents/Dryad01/middleware.properties";
			Properties p = new Properties();
			p.load(new FileInputStream(sp));
//			String dsn = p.getProperty("dbdatasourcename");
			String sn = p.getProperty("dbservername");
//			String dn = "message";
			String dn = p.getProperty("dbdatabasename");
			int port = Integer.parseInt(p.getProperty("dbport"));
//			int port = 6009;
//			String url = "jdbc:postgresql://"+"dryad07.ethz.ch"+":"+port+"/"+dn;
			String url = "jdbc:postgresql://"+sn+":"+port+"/"+dn;
			String u = p.getProperty("dbuser");
			String pass = p.getProperty("dbpassword");
			int mc = Integer.parseInt(p.getProperty("dbmaxconnections"));
//			int mc = 10;
			
			
			//Server configurations
			// jdbc:postgresql://host:port/database
			String host = p.getProperty("serverhost");
			int port1 = Integer.parseInt(p.getProperty("serverport").trim());
			int ms = Integer.parseInt(p.getProperty("servermessagesize").trim());
			int nothreads = Integer.parseInt(p.getProperty("serverthreadpool").trim());
//			int port1 = 5544;
//			int ms = 200;
//			int nothreads = 10;
			
//			PGPoolingDataSource dbConnectionPool = new PGPoolingDataSource();
//			dbConnectionPool.setDataSourceName(dsn);
//			dbConnectionPool.setServerName(sn);
//			dbConnectionPool.setDatabaseName(dn);
//			dbConnectionPool.setUser(u);
//		    dbConnectionPool.setPassword(pass);
//		    dbConnectionPool.setMaxConnections(mc);

			
			ConnectionPool cp = null;
			try {
				cp = new ConnectionPool(mc, url, u, pass, drivername);
			} catch (ClassNotFoundException | SQLException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		ExecutorService servicePool = Executors
			.newFixedThreadPool(nothreads);
	    servicePool.execute(new MessageServer(servicePool,host, port1, ms,cp));
		
	}

}

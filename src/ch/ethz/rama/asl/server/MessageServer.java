package ch.ethz.rama.asl.server;

import java.io.FileInputStream;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.nio.ByteBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.logging.Logger;

import org.postgresql.ds.PGPoolingDataSource;

//import org.postgresql.ds.PGConnectionPoolDataSource;
//import org.postgresql.ds.PGPoolingDataSource;

//import ch.ethz.asl.commons.ChangeRequest;
//import ch.ethz.asl.commons.logging.MessagingSystemLogger;

// adapted from http://rox-xmlrpc.sourceforge.net/niotut/

public class MessageServer implements Runnable {

	private final String host;
	private final int port;

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
    PGPoolingDataSource dbConnectionPool;

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
			 String host, int port, int bufferSize, PGPoolingDataSource dbConnectionPool)
			throws IOException {
		this.host = host;
		this.port = port;
		this.running = true;

		this.messageWorkerPool = messageWorkerPool;
		this.dbConnectionPool = dbConnectionPool;
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

		
		System.out.println("in read 1"+readBuffer.array());
		SocketChannel socketChannel = (SocketChannel) key.channel();
		System.out.println("in read 2"+readBuffer.array());
		// Clear out our read buffer so it's ready for new data
		this.readBuffer.clear();
		System.out.println("in read 3"+readBuffer.array());

		// Attempt to read off the channel
		int numRead;
		try {
			numRead = socketChannel.read(this.readBuffer);
			System.out.println("in read 4"+readBuffer.array());
			
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
		System.out.println("in read 5"+readBuffer.array());
		messageWorkerPool.execute(new MessageWorker(this.dbConnectionPool,this, socketChannel,this.readBuffer.array(), numRead, 0));

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
				System.out.println("in write 6"+buf.toString());
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
//		try {
//			String serverPropFilePath = "properties/middleware.properties";
//			Properties prop = new Properties();
//			prop.load(new FileInputStream(serverPropFilePath));
//
//			// Load Middleware specific properties
//			String host = prop.getProperty("middleware_url");
//			int port = Integer.parseInt(prop.getProperty("middleware_port"));
//			int threadPoolSize = Integer.parseInt(prop
//					.getProperty("middleware_message_handlers_pool_size"));
//			int bufferSize = Integer.parseInt(prop
//					.getProperty("buffer_size"));
//
//			// Load DB specific properties
//			String dataSourceName = prop.getProperty("db_source_name");
//			String dbServerName = prop.getProperty("db_url");
//			String dbName = prop.getProperty("db_name");
//			String dbUser = prop.getProperty("db_username");
//			String dbPassword = prop.getProperty("db_password");
//			int dbConnectionPoolSize = Integer.parseInt(prop
//					.getProperty("db_connection_limit"));
//
//			logger.info(String.format("Starting server on %s:%d", host, port));
//			logger.info(String.format("Middleware config: threadPoolSize=%d",
//					threadPoolSize));
//			logger.info(String.format(
//					"DB config: host=%s,dbName=%s,dbMaxConn=%d", dbServerName,
//					dbName, dbConnectionPoolSize));
//
//			// Start DB Connection Pool
			PGPoolingDataSource dbConnectionPool = new PGPoolingDataSource();
			dbConnectionPool.setDataSourceName("dbsoßurce");
			dbConnectionPool.setServerName("localhost");
			dbConnectionPool.setDatabaseName("message");
			dbConnectionPool.setUser("ramapriyasridharan");
		    dbConnectionPool.setPassword("");
		    dbConnectionPool.setMaxConnections(1);
//
//			// Start Messaging Server
//			// Add N for workers and 1 more for the Selector thread
//			ExecutorService servicePool = Executors
//					.newFixedThreadPool(threadPoolSize + 1);
//			servicePool.execute(new MessageServer(servicePool,
//					dbConnectionPool, host, port, bufferSize));
//
//		} catch (IOException e) {
//			e.printStackTrace();
//		}
		ExecutorService servicePool = Executors
			.newFixedThreadPool(2);
	    servicePool.execute(new MessageServer(servicePool,"localhost", 4444, 200,dbConnectionPool));
		
	}

}

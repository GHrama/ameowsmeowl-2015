package ch.ethz.rama.asl.client;


import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.SocketChannel;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.ResourceBundle;

import ch.ethz.rama.asl.common.*;
class MessagingClient implements Runnable {
	// The host:port combination to connect to
	// private InetAddress hostAddress;
	private String host;
	private int port;

	// Connection(NIO) related variables
	private SocketChannel clientSocketChannel;
	private Selector selector;
	private SelectionKey clientKey;
	boolean running = true;

	// The buffer into which we'll read data when it's available
	private ByteBuffer readBuffer = ByteBuffer.allocate(8192);

	// A list of PendingChange instances
	private List<ChangeRequest> pendingChanges = new LinkedList<ChangeRequest>();

	// Maps a SocketChannel to a list of ByteBuffer instances
	private Map<SocketChannel, List<ByteBuffer>> pendingData = new HashMap<SocketChannel, List<ByteBuffer>>();

	// Maps a SocketChannel to a ResponseHandler
	private Map<SocketChannel, ResponseHandler> rspHandlers = Collections
			.synchronizedMap(new HashMap<SocketChannel, ResponseHandler>());

	public MessagingClient(String host, int port) throws IOException {
		// Setup constants
		// ResourceBundle rb = ResourceBundle.getBundle("resources.server");

		// Setup connection
		// this.clientSocketChannel = SocketChannel.open();

		// nonblocking I/O
		// clientSocketChannel.configureBlocking(false);

		// Connection to host port
		// this.host = rb.getString("server");
		// this.port = Integer.parseInt(rb.getString("port"));
		this.host = host;
		this.port = port;
		// clientSocketChannel.connect(new java.net.InetSocketAddress(host, port));

		// Create selector
		this.selector = Selector.open();
	}
	
	// same
	public void send(byte[] data, ResponseHandler handler) throws IOException {
		// Start a new connection
		SocketChannel socket = this.initiateConnection();

		// Register the response handler
		this.rspHandlers.put(socket, handler);

		// And queue the data we want written
		synchronized (this.pendingData) {
			List<ByteBuffer> queue = this.pendingData.get(socket);
			if (queue == null) {
				queue = new ArrayList<ByteBuffer>();
				this.pendingData.put(socket, queue);
			}
			queue.add(ByteBuffer.wrap(data));
		}

		// Finally, wake up our selecting thread so it can make the required
		// changes
		this.selector.wakeup();
	}

	public void run() {
		while (this.running) {
			try {
				// Process any pending changes
				synchronized (this.pendingChanges) {
					Iterator<ChangeRequest> changes = this.pendingChanges
							.iterator();
					while (changes.hasNext()) {
						ChangeRequest change = (ChangeRequest) changes.next();
						switch (change.type) {
						case ChangeRequest.CHANGEOPS:
							SelectionKey key = change.socket
									.keyFor(this.selector);
							key.interestOps(change.ops);
							break;
							//added this from server!
						case ChangeRequest.REGISTER:
							change.socket.register(this.selector, change.ops);
							break;
						}
					}
					this.pendingChanges.clear();
				}

				// Wait for an event one of the registered channels
				this.selector.select();

				// Iterate over the set of keys for which events are available
				Iterator<SelectionKey> selectedKeys = this.selector
						.selectedKeys().iterator();
				while (selectedKeys.hasNext()) {
					SelectionKey key = (SelectionKey) selectedKeys.next();
					selectedKeys.remove();

					if (!key.isValid()) {
						continue;
					}

					// Check what event is available and deal with it
					if (key.isConnectable()) {
						this.finishConnection(key);
					} else if (key.isReadable()) {
						this.read(key);
					} else if (key.isWritable()) {
						this.write(key);
					}
				}
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
	}

	private void read(SelectionKey key) throws IOException {
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

		if (numRead == -1) {
			// Remote entity shut the socket down cleanly. Do the
			// same from our end and cancel the channel.
			key.channel().close();
			key.cancel();
			return;
		}

		// Handle the response
		this.handleResponse(socketChannel, this.readBuffer.array(), numRead);
	}

	private void handleResponse(SocketChannel socketChannel, byte[] data,
			int numRead) throws IOException {
		// Make a correctly sized copy of the data before handing it
		// to the client
		byte[] rspData = new byte[numRead];
		System.arraycopy(data, 0, rspData, 0, numRead);

		// Look up the handler for this channel
		ResponseHandler handler = (ResponseHandler) this.rspHandlers
				.get(socketChannel);

		// And pass the response to it
		if (handler.handleResponse(rspData)) {
			// The handler has seen enough, close the connection
			socketChannel.close();
			socketChannel.keyFor(this.selector).cancel();
		}
	}

	private void write(SelectionKey key) throws IOException {
		SocketChannel socketChannel = (SocketChannel) key.channel();
		System.out.println("in read 1"+readBuffer.array());

		synchronized (this.pendingData) {
			List<ByteBuffer> queue = this.pendingData.get(socketChannel);

			// Write until there's not more data ...
			while (!queue.isEmpty()) {
				ByteBuffer buf = (ByteBuffer) queue.get(0);
				System.out.println("in read 2"+buf.array());
				socketChannel.write(buf);
				if (buf.remaining() > 0) {
					// ... or the socket's buffer fills up
					break;
				}
				queue.remove(0);
			}
			System.out.println("in read 3"+readBuffer.array());

			if (queue.isEmpty()) {
				// We wrote away all data, so we're no longer interested
				// in writing on this socket. Switch back to waiting for
				// data.
				key.interestOps(SelectionKey.OP_READ);
			}
		}
	}

	private void finishConnection(SelectionKey key) throws IOException {
		SocketChannel socketChannel = (SocketChannel) key.channel();

		// Finish the connection. If the connection operation failed
		// this will raise an IOException.
		try {
			socketChannel.finishConnect();
		} catch (IOException e) {
			// Cancel the channel's registration with our selector
			System.out.println(e);
			key.cancel();
			return;
		}

		// Register an interest in writing on this channel
		key.interestOps(SelectionKey.OP_WRITE);
	}
	
	
	//same
	private SocketChannel initiateConnection() throws IOException {
		// Create a non-blocking socket channel
		SocketChannel socketChannel = SocketChannel.open();
		socketChannel.configureBlocking(false);

		// Kick off connection establishment
		socketChannel.connect(new java.net.InetSocketAddress(host, port));

		// Queue a channel registration since the caller is not the
		// selecting thread. As part of the registration we'll register
		// an interest in connection events. These are raised when a channel
		// is ready to complete connection establishment.
		synchronized (this.pendingChanges) {
			this.pendingChanges.add(new ChangeRequest(socketChannel,
					ChangeRequest.REGISTER, SelectionKey.OP_CONNECT, System.currentTimeMillis()));
		}

		return socketChannel;
	}

	public static void main(String[] args) {
		try {
			MessagingClient client = new MessagingClient("localhost", 4444);
			Thread t = new Thread(client);
			t.start();
			ResponseHandler handler = new ResponseHandler();
			client.send("meow ndksfdksfhdsf fdshfswfjdklsf".getBytes(), handler);
			String s = handler.waitForResponse();
			System.out.println(s);
			client.running = false;
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

}


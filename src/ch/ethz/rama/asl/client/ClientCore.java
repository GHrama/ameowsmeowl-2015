package ch.ethz.rama.asl.client;
// code adapted from here http://www.ibm.com/developerworks/library/j-nio2-1/

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.AsynchronousSocketChannel;
import java.nio.channels.SocketChannel;
import java.nio.charset.Charset;
import java.util.concurrent.ExecutionException;



//public class ClientCore  {
//
//	// client 
//	// initiate a connection
//	// get host,port and message size
//	// send method to send to server
//	// hand over to response handler
//	// wait for a response from server
//	// return response and process in client optionsß
//	
//	String host;
//	int port;
//	int buff_size;
//	InetSocketAddress inet;
//	AsynchronousSocketChannel asyn;
//	ClientCore(String host, int port, int buff_size) throws IOException{
//		
//		this.host = host;
//		this.buff_size = buff_size+100;// +100?
//		this.port = port;
//		inet = new InetSocketAddress(host,port);
//		asyn = AsynchronousSocketChannel.open();
//		try{
//			asyn.connect(inet).get();
//			
//		}catch (InterruptedException | ExecutionException e) {
//			e.printStackTrace();
//			throw new IOException("Execution was interrupted: "
//					+ e.getMessage());
//		}
//		
//		
//	}
//	
//	// send request to middleware
//	// 
//	public void send(byte[] data,ResponseHandler rsp){
//		byte[] response ;
//		response = "ERROR".getBytes();
//		try{
//			// put data in buffer
//			ByteBuffer tosend = ByteBuffer.wrap(data);
//			ByteBuffer toget = ByteBuffer.allocateDirect(buff_size);
//
//			asyn.write(tosend).get();
//			// By adding .get(), this becomes a blocking call.
//			int numRead = asyn.read(toget).get();
//			
//			// always flip before
//			toget.flip();
//			
//			// make the buffer content into string
//			String rspStr = Charset.defaultCharset().decode(toget).toString();
//			response = rspStr.getBytes();
//
//		} catch (InterruptedException e) {
//			e.printStackTrace();
//		} catch (ExecutionException e) {
//			e.printStackTrace();
//		} finally {
//			// close connection?
//		}
//
//		rsp.handleResponse(response);
//	}
//			
//		
//		
//}


public class ClientCore {

	private String host;
	private int port;
	InetSocketAddress hostInet;
	AsynchronousSocketChannel channel;

	private final int BUFFER_SIZE;

	public ClientCore(String host, int port, int bufferSize) throws IOException {
		this.host = host;
		this.port = port;
		this.BUFFER_SIZE = bufferSize + 100;
		
		hostInet = new InetSocketAddress(this.host, this.port);
		channel = AsynchronousSocketChannel.open();
		try {
			channel.connect(hostInet).get();
		} catch (InterruptedException | ExecutionException e) {
			e.printStackTrace();
			throw new IOException("Execution was interrupted: "
					+ e.getMessage());
		}
	}


	public void send(byte[] data, ResponseHandler handler) throws IOException {
		byte[] rspData = "ERROR".getBytes(); // Send a string "ERROR" in case
												// something went wrong.
												// ClientAPI will handle this
												// accordingly.

		try {
			
			ByteBuffer sendStr = ByteBuffer.wrap(data);
			
			ByteBuffer rcv = ByteBuffer.allocateDirect(BUFFER_SIZE);
			

			channel.write(sendStr).get();
			// By adding .get(), this becomes a blocking call.
			int numRead = channel.read(rcv).get();

			rcv.flip();

			String rspStr = Charset.defaultCharset().decode(rcv).toString();
			rspData = rspStr.getBytes();

		} catch (InterruptedException e) {
			e.printStackTrace();
		} catch (ExecutionException e) {
			e.printStackTrace();
		} finally {
		}

		handler.handleResponse(rspData);
	}

}

	
	
	
	
	


package ch.ethz.rama.asl.client;
// code adapted from here http://www.ibm.com/developerworks/library/j-nio2-1/
// mostly from here http://www.java2s.com/Tutorials/Java/Java_Network/0080__Java_Network_Asynchronous_Socket_Channels.htm

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.AsynchronousSocketChannel;
import java.nio.channels.SocketChannel;
import java.nio.charset.Charset;
import java.util.concurrent.ExecutionException;

// TODO change before submission

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
		} catch (Exception e) {
			e.printStackTrace();
			
		}
	}


	public void send(byte[] data, ResponseHandler handler) throws IOException {
		byte[] rspData = "SOMETHING;WENT;WRONG;???".getBytes(); 

		try {
			
			ByteBuffer sendStr = ByteBuffer.wrap(data);
			
			ByteBuffer rcv = ByteBuffer.allocateDirect(BUFFER_SIZE);
			

			channel.write(sendStr).get();
			// By adding .get(), this becomes a blocking call.
			int numRead = channel.read(rcv).get();

			rcv.flip();

			String rspStr = Charset.defaultCharset().decode(rcv).toString();
			rspData = rspStr.getBytes();

		} catch (Exception e) {
			e.printStackTrace();
		} 

		handler.handleResponse(rspData);
	}

}

	
	
	
	
	


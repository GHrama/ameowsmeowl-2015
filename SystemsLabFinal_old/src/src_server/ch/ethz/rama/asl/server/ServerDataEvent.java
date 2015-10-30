package ch.ethz.rama.asl.server;

import java.nio.channels.SocketChannel;


public class ServerDataEvent {
	public MessageServer server;
	public SocketChannel socket;
	public byte[] data;

	public ServerDataEvent(MessageServer server,
			SocketChannel socket, byte[] data) {
		this.server = server;
		this.socket = socket;
		this.data = data;
	}

}

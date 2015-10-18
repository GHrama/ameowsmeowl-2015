package ch.ethz.rama.asl.common;


import java.nio.channels.SocketChannel;

public class ChangeRequest {

	public static final int REGISTER = 1;
	public static final int CHANGEOPS = 2;

	public SocketChannel socket;
	public int type;
	public int ops;
	public long arrivalTime;

	public ChangeRequest(SocketChannel socket, int type, int ops, long arrivalTime) {
		this.socket = socket;
		this.type = type;
		this.ops = ops;
		this.arrivalTime = arrivalTime;
	}
}

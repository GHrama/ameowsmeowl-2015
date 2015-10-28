package ch.ethz.rama.asl.client;


// adapted from https://docs.oracle.com/javase/tutorial/i18n//message.html

import java.text.MessageFormat;

public class ClientSerializer {

	static String end = "?";
	static MessageFormat addQueue = new MessageFormat(
			"ADDQUEUE;{0,number,integer};{1};" + end);
	static  MessageFormat addClient = new MessageFormat(
			"ADDCLIENT;{0,number,integer};" + end);
	static MessageFormat delQueue = new MessageFormat(
			"DELQUEUE;{0,number,integer};{1,number,integer};" + end);
	static MessageFormat sendMsg = new MessageFormat(
			"SENDMSG;{0,number,integer};{1,number,integer};{2,number,integer};{3};" + end);
	static MessageFormat getLatestMsg = new MessageFormat(
			"GETLATESTMSG;{0,number,integer};{1,number,integer};" + end);
	static MessageFormat getLatestMsgDel = new MessageFormat(
			"GETLATESTMSGDEL;{0,number,integer};{1,number,integer};" + end);
	static MessageFormat getFromSenderMsg = new MessageFormat(
			"GETSENDERMSG;{0,number,integer};{1,number,integer};{2,number,integer};" + end);
	static MessageFormat getFromSenderMsgDel = new MessageFormat(
			"GETSENDERMSGDEL;{0,number,integer};{1,number,integer};{2,number,integer};" + end);
	static MessageFormat getQueues = new MessageFormat(
			"GETQUEUES;{0,number,integer};" + end);
	

	public static String eAddQueue(int clientID, String queueName) {
		Object[] args = { clientID, queueName };
		return addQueue.format(args);
	}
	
	public static String eAddClient(int clientID) {
		Object[] args = { clientID };
		return addClient.format(args);
	}

	public static String eDeleteQueue(int clientID, int queueID) {
		Object[] args = { clientID, queueID };
		return delQueue.format(args);
	}

	public static String eSendMessage(int queueID, int senderID,
			int receiverID, String message) {
		Object[] args = { queueID, senderID, receiverID, message };
		return sendMsg.format(args);
	}

	public static String eRetrieveLatestMessage(int queueID,
			int receiverID) {
		Object[] args = { queueID, receiverID };
		return getLatestMsg.format(args);
	}
	
	public static String eRetrieveLatestMessageDelete(int queueID,
			int receiverID) {
		Object[] args = { queueID, receiverID};
		return getLatestMsgDel.format(args);
	}

	public static String eRetrieveMessageFromSender(int queueID,
			int receiverID, int senderID) {
		Object[] args = { queueID, receiverID, senderID };
		return getFromSenderMsg.format(args);
	}
	
	public static String eRetrieveMessageFromSenderDelete(int queueID,
			int receiverID, int senderID) {
		Object[] args = { queueID, receiverID, senderID};
		return getFromSenderMsgDel.format(args);
	}

	public static String eQueuesWithMessages(int clientID) {
		Object[] args = { clientID };
		return getQueues.format(args);
	}

	public static void main(String[] args) {

		
	}

}
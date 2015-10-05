package ch.ethz.rama.asl.client;


// adapted from https://docs.oracle.com/javase/tutorial/i18n//message.html

import java.text.MessageFormat;

public class ClientSerializer {

	
	static String end = "???";
	// ADDQUEUE;clientid;queueName;???
	static MessageFormat createQueue = new MessageFormat(
			"ADDQUEUE;{0,number,integer};{1};" + end);
	// ADDCLIENT;client;???
	static  MessageFormat createClient = new MessageFormat(
			"ADDCLIENT;{0,number,integer};" + end);
	// DELETEQUEUE;clientid;queueid;???
	static MessageFormat deleteQueue = new MessageFormat(
			"DELETEQUEUE;{0,number,integer};{1,number,integer};" + end);
	// SENDMSG;queueid;senderid;receiverid;payload;???
	static MessageFormat sendMessage = new MessageFormat(
			"SENDMSG;{0,number,integer};{1,number,integer};{2,number,integer};{3};" + end);
	// RETVLATESTMSG;queueid;receiverid;???
	static MessageFormat retrieveLatestMessage = new MessageFormat(
			"RETVLATESTMSG;{0,number,integer};{1,number,integer};" + end);
	// RETVLATESTMSGDELETE;queueid;receiverid;???
	static MessageFormat retrieveLatestMessageDelete = new MessageFormat(
			"RETVLATESTMSGDELETE;{0,number,integer};{1,number,integer};" + end);
	// RETVSENDERMSG;queueid;receiverid;senderid;???
	static MessageFormat retrieveFromSenderMessage = new MessageFormat(
			"RETVSENDERMSG;{0,number,integer};{1,number,integer};{2,number,integer};" + end);
	// RETVSENDERMSGDELETE;queueid;receiverid;senderid;???
	static MessageFormat retrieveFromSenderMessageDelete = new MessageFormat(
			"RETVSENDERMSGDELETE;{0,number,integer};{1,number,integer};{2,number,integer};" + end);
	// QUEUESWITHMSG;clientid;???
	static MessageFormat queuesWithMessages = new MessageFormat(
			"QUEUESWITHMSG;{0,number,integer};" + end);
	

	public static String eAddQueue(int clientID, String queueName) {
		Object[] args = { clientID, queueName };
		return createQueue.format(args);
	}
	
	public static String eAddClient(int clientID) {
		Object[] args = { clientID };
		return createClient.format(args);
	}

	public static String eDeleteQueue(int clientID, int queueID) {
		Object[] args = { clientID, queueID };
		return deleteQueue.format(args);
	}

	public static String eSendMessage(int queueID, int senderID,
			int receiverID, String message) {
		Object[] args = { queueID, senderID, receiverID, message };
		return sendMessage.format(args);
	}

	public static String eRetrieveLatestMessage(int queueID,
			int receiverID) {
		Object[] args = { queueID, receiverID };
		return retrieveLatestMessage.format(args);
	}
	
	public static String eRetrieveLatestMessageDelete(int queueID,
			int receiverID) {
		Object[] args = { queueID, receiverID};
		return retrieveLatestMessageDelete.format(args);
	}

	public static String eRetrieveMessageFromSender(int queueID,
			int receiverID, int senderID) {
		Object[] args = { queueID, receiverID, senderID };
		return retrieveFromSenderMessage.format(args);
	}
	
	public static String eRetrieveMessageFromSenderDelete(int queueID,
			int receiverID, int senderID) {
		Object[] args = { queueID, receiverID, senderID};
		return retrieveFromSenderMessageDelete.format(args);
	}

	public static String eQueuesWithMessages(int clientID) {
		Object[] args = { clientID };
		return queuesWithMessages.format(args);
	}

	public static void main(String[] args) {

		System.out.println(eAddQueue(42, "abc"));
		System.out.println(eDeleteQueue(100, 23));
		System.out.println(eSendMessage(45, 10, 20, "Hello world!"));
		System.out.println(eRetrieveLatestMessage
(12, 43));
		System.out
				.println(eRetrieveMessageFromSender(90, 101, 123));
		System.out.println(eQueuesWithMessages(55));
	}

}
package ch.ethz.rama.asl.common;

public enum RequestType {
	ADD_QUEUE("ADDQUEUE"), DELETE_QUEUE("DELETEQUEUE"), SEND_MESSAGE(
			"SENDMSG"), RETV_LATEST_MESSAGE("RETVLATESTMSG"), RETV_LATEST_MESSAGE_DELETE("RETVLATESTMSGDELETE"),RETV_SENDER_MESSAGE(
			"RETVSENDERMSG"),RETV_SENDER_MESSAGE_DELETE(
					"RETVSENDERMSGDELETE"), QUEUES_WITH_MESSAGE("QUEUESWITHMSG"), ADD_CLIENT("ADDCLIENT");
	
	private final String textLiteral;

	private RequestType(final String textLiteral) {
		this.textLiteral = textLiteral;
	}

	@Override
	public String toString() {
		return this.textLiteral;
	}
}

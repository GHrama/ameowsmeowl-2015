package ch.ethz.rama.asl.common;

public enum Type {
	ADD_QUEUE("ADDQUEUE"), DEL_QUEUE("DELQUEUE"), SEND_MSG(
			"SENDMSG"), GET_LATEST_MSG("GETLATESTMSG"), GET_LATEST_MSG_DEL("GETLATESTMSGDEL"),GET_SENDER_MSG(
			"GETSENDERMSG"),GET_SENDER_MSG_DEL(
					"GETSENDERMSGDEL"), GET_QUEUES("GETQUEUES"), ADD_CLIENT("ADDCLIENT");
	
	private final String textLiteral;

	private Type(final String textLiteral) {
		this.textLiteral = textLiteral;
	}

	@Override
	public String toString() {
		return this.textLiteral;
	}
}

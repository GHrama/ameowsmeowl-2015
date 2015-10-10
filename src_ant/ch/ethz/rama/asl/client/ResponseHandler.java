package ch.ethz.rama.asl.client;

// wait for the server to respond,notify thread and return response.
// from response only take necessary arguments
// adpated from http://rox-xmlrpc.sourceforge.net/niotut/

public class ResponseHandler {
	private byte[] rsp = null;

	public synchronized boolean handleResponse(byte[] rsp) {
		this.rsp = rsp;
		this.notify();
		return true;
	}

	public synchronized String waitForResponse() {
		while (this.rsp == null) {
			try {
				this.wait();
				// interrupt thread
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		}

		String response = new String(this.rsp);
		return response;
	}
}

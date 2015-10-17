package ch.ethz.rama.asl.logging;

import java.util.logging.Formatter;
import java.util.logging.LogRecord;

public class MyFormatter extends Formatter {

	@Override
	public String format(LogRecord record) {
		// TODO Auto-generated method stub
		StringBuilder r = new StringBuilder();
		r.append("<")
			.append(record.getMillis())
			.append(">")
			.append(" ")
			.append(record.getSourceClassName())
			.append(" ")
			.append(record.getSourceMethodName())
			.append(" ")
			.append(record.getThreadID())
			.append(" ")
			.append(record.getLevel())
			.append(" ")
			.append(record.getMessage())
			.append(System
			.getProperty("line.separator"));
		
			return r.toString();
	}
	
	

}

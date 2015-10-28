package ch.ethz.rama.asl.logging;
import java.io.IOException;
import java.util.concurrent.TimeUnit;
import java.util.logging.ConsoleHandler;
import java.util.logging.FileHandler;
import java.util.logging.Handler;
import java.util.logging.Level;
import java.util.logging.Logger;

public class MyLogger {
	
	static MyFormatter formatter = null;
	static FileHandler fileHandler = null;
	static ConsoleHandler consoleHandler = null;
	static String preName = "";
	static Long time = System.currentTimeMillis();
	//static String file_path = "/tmp/rsridhar-"+preName+time+".log";
	
	static String file_path = "/tmp/rsridhar-"+preName+time+".log";
	// setup method
	static public void setup() throws SecurityException, IOException {
//		if(fileHandler == null)
		fileHandler = new FileHandler(file_path, true);
		if(consoleHandler == null)
			consoleHandler = new ConsoleHandler();
		if(formatter == null)
			formatter = new MyFormatter();	
		}
	
	static public Logger classLogger(String className){
		Logger logger = Logger.getLogger(className);
		logger.setUseParentHandlers(false);
		
			try {
				setup();
				fileHandler.setFormatter(formatter);
				if(consoleHandler == null || formatter == null)
				consoleHandler.setFormatter(formatter);
				
//				Handler[] handlers = logger.getHandlers();
//				 //array of registered handlers
//				for (int i = 0; i < handlers.length; i++)
//					logger.removeHandler(handlers[i]);
//				
				logger.setLevel(Level.INFO);
				logger.addHandler(fileHandler);
				
			} catch (SecurityException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		
		return logger;
	}
	
	static public Logger classLogger(String className,
			String log_prefix) {
		preName = log_prefix;
		//file_path = "/tmp/rsridhar-"+preName+time+".log";
		file_path = "/tmp/rsridhar-"+preName+time+".log";
		return classLogger(className);
	}
	

}

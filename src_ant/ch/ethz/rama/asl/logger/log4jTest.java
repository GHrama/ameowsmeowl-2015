package ch.ethz.rama.asl.logger;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Properties;

import org.apache.log4j.Logger;
import org.apache.log4j.PropertyConfigurator;

import ch.ethz.rama.asl.client.ClientInstance;

public class log4jTest {
	
	static Logger log = Logger.getLogger(ch.ethz.rama.asl.client.ClientInstance.class);
	
	public static void main(String args[]) throws FileNotFoundException, IOException{
		Properties props = new Properties();
		props.load(new FileInputStream("/Users/ramapriyasridharan/Documents/asl_v1/ClientServerNio/bin/log4j.properties"));
		PropertyConfigurator.configure(props);
		log.debug("meow");
		log.info("info meow");
	}

}

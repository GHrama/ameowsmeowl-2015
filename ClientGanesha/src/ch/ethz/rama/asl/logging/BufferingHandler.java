
package ch.ethz.rama.asl.logging;


import java.io.IOException;
import java.util.Queue;
import java.util.concurrent.*;
import java.util.logging.FileHandler;
import java.util.logging.LogRecord;

public class BufferingHandler extends FileHandler implements AutoCloseable {

    private final Queue<LogRecord> logRecordsFifo = new ConcurrentLinkedQueue<>();
    private final ScheduledExecutorService scheduler = Executors.newSingleThreadScheduledExecutor();

    public BufferingHandler(final String pattern, final int delay, final TimeUnit timeUnit) throws SecurityException, IOException {
        super(pattern);
        scheduler.scheduleWithFixedDelay(new Runnable() {
			@Override
			public void run() {
				handleLogs();
			}
		}, delay, delay, timeUnit);
    }

    private void handleLogs() {
        while (!logRecordsFifo.isEmpty()) {
            // sync is required to preserve logs order when flushing
            synchronized (logRecordsFifo) { 
                final LogRecord log = logRecordsFifo.poll();
                if (log != null) super.publish(log);
            }
        }
    }

    @Override
    public void publish(final LogRecord record) {
        if (!isLoggable(record)) return;
        logRecordsFifo.add(record);
    }

    @Override
    public void flush() {
        handleLogs();
        super.flush();
    }

    @Override
    public void close() {
        scheduler.shutdown();
        flush();
        super.close();
    }
}

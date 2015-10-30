--Hello Welcome to Ganesha Messaging System!



--Directory Structure :
-src : Program source files of client and server
-Report : Contains report
-Data : Sorted by data,experiment type
-lib : Libraries used
-DeployScriptsAndOtherRelevantFiles : This contains
1. Python script dryad.py and dryad_easy.py, it is recommended to use dryad_easy.py, it allows for multiple
   experiments by changing important configurations such as duration,server,clients,database in only the first file.
   (Since focus of this course was not to make perfect scripts, scripts might be buggy but generally run well!)
2. Dryad01.ini is an example configuration file, most parameters are well tuned, what you can vary is :
	1. duration
	2. server
	3. client
	4. server
	5. And the number of each server and client machines/threads,the config file must be self explanatory,
	care was taken to choose appropriate variable names to make it easy for anyone to use.
	NOTE : Don't forget to set the database username to yours!
3. dbFiles contains the
	1. postgres configurations files
	2. postgres tar file
	3. database schema used during the experiments, the schema used entirely was non-empty, an empty schema was never used!
	



--INSTRUCTIONS- How to run Ganesha:
1. Please run ant 'jar_server' and 'ant jar_client' in main directory.
2. Go to DeployScriptsAndOtherRelevantFiles directory. 
3. Run the following command 'python dryad_easy.py Experiment_list_ec2.txt' .
4. Experiment_list_ec2.txt contains the Dryad01.ini configuration file location, which you can modify of course,
   it is right now set to run on the dryad. In this way multiply file experiments can be run one after the other!
5. All experiment outputs should be in output folder, all zipped with the experiment id.
6. You can use unzip_files.py to unzip all files if many are present, the reason for zipping 
   was that some files took forever to download!
   NOTE : Using this is only useful when you have more than 4/5 files to unzip.




--INSTRUCTIONS- How to plot Ganesha Data:
1. The plot scripts are made to accept many file directories, each containing
	1 repetition of the same experiment.
2. In the plot file you should give the link to the file that contains all data main directories,
	for example :
	Ramapriya/rep1/01
	Ramapriya/rep2/01
	Ramapriya/rep3/01
	
	Lets say I am measuring the efficient number of threads at the server, and I place all my results under folder
	Ramapriya, and I do 3 such repetitions. For server thread count 10 I place under foler 01,for thread 20,under 02 and so on
	for each repetition 1-3.
	So the main directory is Ramapriya/rep1
							 Ramapriya/rep2
							 Ramapriya/rep3

	You should paste this link in edit-me-for-graphs.txt everything else has been automated.
3.  NOTE: This is required only if you change the directory path, or want to process multiple data together.
	
	
	
	
	
	
	-- Thanks for taking the time to evaluate the project!! ^^
	Ramapriya Sridharan
	
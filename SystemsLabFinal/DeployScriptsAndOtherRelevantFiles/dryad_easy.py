__author__ = 'ramapriyasridharan'
import os, pprint
import paramiko
from fabric.api import *
import time
from server import *
from general import *
import argparse
import ConfigParser
from postgres_magic import *



# Script based on this tutorial http://www.linuxjournal.com/content/fabric-system-administrators-best-friend
def main():
	'''
	Enter the experiment .ini file path
	'''
	parser = argparse.ArgumentParser()
	parser.add_argument("experimentlist", help="Provide file with series of experiments, Please refer to the ../README.txt")
	args = parser.parse_args()

	# experimentlist is a .ini file location
	# Read it
	exp_list = []
	#has list of experiment paths_config
	with open(args.experimentlist) as f:
		for line in f:
			line = line.strip()
			exp_list.append(line)

	print exp_list

	# config files have almost same init_info
	config = ConfigParser.ConfigParser()
	config.read(exp_list[0])

	# DB_HOST
	#get directly from first file,so need to change in all file!!
	db_host = config.get("database", "dbservername")

	##########################################################
	##########################################################
	### START EXP init_info ######################################
	##########################################################
	##########################################################

	#get list of middleware and clients
	middleware_set = set([x[0] for x in config.items("mapping")])
	#client_set = set([x[0] for x in configFile.items("mapping")])
	client_set = set()
	for (mw, clients) in config.items("mapping"):
		cl_list = clients.split(',')
		client_set |= set(cl_list)
	print "CLIENTS: ", client_set

	print middleware_set
	print client_set

	mw_cl_map = {}
	for mw, cl in config.items("mapping"):
			item_list = cl.split(',')
			for item in item_list:
				mw_cl_map[item] = mw

	database_port = config.get("server_properties", "dbport")

	# DB
	# Now init_info db engine
	# Need to first install postgres-9.4.0 on dryad
	# java already installed



	if config.get("init_info","amazon_machine") in ["True","true"]:
		pem_key_path = config.get("paths_config","pem_key_path")
		rsridhar_install_remote_stuff(config.get("init_info", "username"),
						  db_host,
						  config.get("paths_config", "pem_key_path"),
						  )
	else:
		pem_key_path=None


	'''rsridhar_install_db_remote(config.get("init_info", "username"),
				   database_port,
				   db_host,
				   config.get("paths_config", "rsridhar_schema"),
				   config.get("paths_config", "pg_hba_conf_path"),
				   config.get("paths_config", "rsridhar_conf_path"),
				   config.get("paths_config", "rsridhar_db_path"),
				   False,
				   pem_key_path,
				   config.get("server_properties", "dbdatabasename")
	)'''
	experiment_id = config.get("rsridhar_start", "id")
	directory = config.get("rsridhar_start", "output_dir")

	if config.get("init_info","amazon_machine") in ["True","true"]:
		java_path = config.get("java_info","amazon_java_path")
	else:
		java_path = config.get("java_info", "dryad_java_path")
	username = config.get("init_info", "username")

	if config.get("init_info", "amazon_machine") in ["True", "true"]:
			for mw_host in middleware_set:
				rsridhar_install_remote_stuff(config.get("init_info", "username"),
					  mw_host,
					  config.get("paths_config", "pem_key_path"),
					  )
				rsridhar_install_java_remote(config.get("init_info", "username"),
					  mw_host,
					  config.get("paths_config", "pem_key_path"),
					  )
	time_exp = config.get("duration","duration")

	# 3. Set up Client machine
	# 3.a. Install necessary applications

	if config.get("init_info", "amazon_machine") in ["True", "true"]:
			for cl_host in client_set:
				rsridhar_install_remote_stuff(config.get("init_info", "username"),
					  cl_host,
					  config.get("paths_config", "pem_key_path"),
					  )
				rsridhar_install_java_remote(config.get("init_info", "username"),
					  cl_host,
					  config.get("paths_config", "pem_key_path"),
					  )

	for experiment in exp_list:
		# initialize all middlewares
		# assume java already installed
		#make middleware-client mapping
		# a map with clinet gives middleware

		configFile = ConfigParser.ConfigParser()
		configFile.read(experiment)
		experiment_id = configFile.get("rsridhar_start", "id")
		directory = configFile.get("rsridhar_start", "output_dir")


		#store list of what middleare connected to what client
		print mw_cl_map
		#debug
		print 'id ::', experiment_id
		print 'directory ::', directory
		print 'username ::', username
		print 'pem_key_file::', pem_key_path

		print 'db_host ::', db_host
		print 'mw_host ::', middleware_set
		print 'cl_host ::', client_set

		for mw_host in middleware_set:
			print mw_host
			rsridhar_remote_exe_bash(username,
					   mw_host,
					   pem_key_path,
					   "mkdir -p /local/rsridhar/%s/properties" % experiment_id)

			with warn_only():
				rsridhar_remote_exe_bash(username,
						   mw_host,
						   pem_key_path,
						   args.experimentlist,
						   "mkdir -p /local/rsridhar/logs")

			rsridhar_to_remote(username,
						  mw_host,
						  pem_key_path,
						  args.experimentlist,
						  "/local/rsridhar/%s" % experiment_id)

		# now init_info client machine
		# java already installed
		for cl_host in client_set:
			print cl_host
			rsridhar_remote_exe_bash(username,
					   cl_host,
					   pem_key_path,
					   "mkdir -p /local/rsridhar/%s/properties" % experiment_id)
			with warn_only():
				rsridhar_remote_exe_bash(username,
						   cl_host,
						   pem_key_path,
						   "mkdir -p /local/rsridhar/logs")

			rsridhar_to_remote(username,
						  cl_host,
						  pem_key_path,
						  args.experimentlist,
						  "/local/rsridhar/%s" % experiment_id)





		# Clean start DB
		#kill server process before db start

		#kill all programs taking up db connections
		for cl_host in client_set:
			with warn_only():
				rsridhar_remote_exe_bash(username,
						   cl_host,
						   pem_key_path,
						   "killall java",
				)


		for mw_host in middleware_set:
			with warn_only():
				rsridhar_remote_exe_bash(username,
						   mw_host,
							pem_key_path,
						   "killall java",
			)


		rsridhar_db_start_stop(username,
						 db_host,
						 pem_key_path,
						 "start")
		# Recreate DB
		rsridhar_install_db_remote_again(username,
				  database_port,
				  db_host,
				  configFile.get("paths_config", "rsridhar_schema"),
				  pem_key_path,
				  config.get("server_properties", "dbdatabasename")
				  )


		# Move middleware jar to middleware
		for mw_host in middleware_set:
			rsridhar_to_remote(username,
						  mw_host,
						  pem_key_path,
						  configFile.get("paths_config", "server_jar"),
						  "/local/rsridhar/%s/server.jar" % experiment_id)

			# create middleware property file
			# for each middleware and
			# place them under properties folder

			# create this file
			prop_file_on_local_machine_S = '%s/middleware.properties' % directory
			with open(prop_file_on_local_machine_S, 'w') as f:
				f.write("serverhost=%s\n" % mw_host)
				f.write("dbservername=%s\n"% db_host)
				# f.write("buffer_size=%s \n"%configFile.get("prop_client","message_size"))
				for keys in configFile.options("server_properties"):
					f.write("%s=%s\n" % (keys, configFile.get("server_properties", keys)))

			rsridhar_to_remote(configFile.get("init_info", "username"),
						  mw_host,
						  pem_key_path,
						  prop_file_on_local_machine_S,
						  "/local/rsridhar/%s/properties" % experiment_id)

		for cl_host in client_set:
			# move client jars to client host
			rsridhar_to_remote(username,
						  cl_host,
						  pem_key_path,
						  configFile.get("paths_config", "client_jar"),
						  "/local/rsridhar/%s/client.jar" % experiment_id)


			# copy properties file
			prop_file_on_local_machine_C = "%s/client.properties" % directory
			with open(prop_file_on_local_machine_C, "w") as fc:
				fc.write("serverhost=%s\n" % mw_cl_map[cl_host])
				#fc.write("middleware_url=%s \n" % mw_host)
				for keys in configFile.options("client_properties"):
					fc.write("%s=%s\n" % (keys, configFile.get("client_properties", keys)))

					# copy files to host
			rsridhar_to_remote(username,
						  cl_host,
						  pem_key_path,
						  prop_file_on_local_machine_C,
						  "/local/rsridhar/%s/properties" % experiment_id)

	####################################################
	################# START EXPERIMENT
	####################################################


		######################
		#start middleware
		middle_jar_path = "/local/rsridhar/%s/server.jar" % experiment_id
		# usually no command arguments from middleware
		cmd_args = ''
		for option in configFile.options('prop_server'):
			cmd_args += ' %s ' % (option, configFile.get('prop_server', option))
		middle_command = "%s -jar %s %s 2>%s.err" % (java_path, middle_jar_path, cmd_args, experiment_id)

		#kill existing java processes on server

		for mw_host in middleware_set:
			with warn_only():
				rsridhar_remote_end_other_java(configFile.get("init_info", "username"),
							mw_host,
							pem_key_path)
		# on clien
		for cl_host in client_set:
			with warn_only():
				rsridhar_remote_end_other_java(configFile.get("init_info", "username"),
							cl_host,
							pem_key_path)

		# for each host: of middleware
		bshf = open('/tmp/run.sh', 'w')
		bshf.write('#!/bin/bash\n')
		bshf.write(middle_command)
		bshf.close()

		for mw_host in middleware_set:
			rsridhar_to_remote(username,
						  mw_host,
						  pem_key_path,
						  '/tmp/run.sh',
						  "/local/rsridhar/%s/run.sh" % experiment_id
			)

			with warn_only():
				rsridhar_remote_exe_bash(username,
						   mw_host,
						   pem_key_path,
						   "rm /tmp/rsrid*",
						   use_cwd='/local/rsridhar/%s' % experiment_id
				)
				rsridhar_remote_exe_bash(username,
					   mw_host,
					   pem_key_path,
					   "chmod 777 run.sh",
					   use_cwd='/local/rsridhar/%s' % experiment_id
			)
			rsridhar_remote_exe_bash(username,
					   mw_host,
					   pem_key_path,
					   "screen -S mbs2 -d -m ./run.sh; sleep 1",
					   use_cwd='/local/rsridhar/%s' % experiment_id
			)


		#start client
		# feed this to the clients
		machine_num = 1
		for cl_host in client_set:
			cmd_args = ''
			cmd_args += ' %d ' % machine_num
			machine_num += 1;
			for option in configFile.options("prop_client"):
				cmd_args += ' %s ' % (configFile.get("prop_client", option))
			cmd_args += ' %s ' %time_exp

			print 'Client machines :: ', cl_host
			print 'Client commands :: ', cmd_args
			#for(machine_num,cl_hos) in enumerate(cl_host):

			#add machine id for each machine
			#cmd_args_this_host = cmd_args + "--machine_id %d" %machine_num
			client_cmd = "%s -jar client.jar %s  2>%s.err" % (java_path, cmd_args, experiment_id)

			cf = open('/tmp/clientrun.sh', 'w')
			cf.write('#!/bin/bash\n')
			cf.write(client_cmd)
			cf.close()

			rsridhar_to_remote(username,
						  cl_host,
						  pem_key_path,
						  '/tmp/clientrun.sh',
						  "/local/rsridhar/%s/clientrun.sh" % experiment_id)

			with warn_only():
				rsridhar_remote_exe_bash(username,
						   cl_host,
						   pem_key_path,
						   "rm /tmp/rsrid*",
						   use_cwd='/local/rsridhar/%s' % experiment_id
				)
				rsridhar_remote_exe_bash(username,
						   cl_host,
						   pem_key_path,
						   "chmod 777 clientrun.sh",
						   use_cwd='/local/rsridhar/%s' % experiment_id
				)
				rsridhar_remote_exe_bash(username,
						   cl_host,
						   pem_key_path,
						   "screen -S client2 -d -m ./clientrun.sh; sleep 1",
						   use_cwd='/local/rsridhar/%s' % experiment_id
				)


		#############################
		# wait for execution to complete
		sleep_time_secs = int(time_exp)
		print 'sleeping for %d secs' % int(sleep_time_secs)
		time.sleep(sleep_time_secs)
		print ' completed sleep. '
		time.sleep(5)


		#Breakdown everything
		for cl_host in client_set:
			with warn_only():
				rsridhar_remote_exe_bash(username,
						   cl_host,
						   pem_key_path,
						   "killall java",
				)
				rsridhar_remote_exe_bash(username,
						   cl_host,
						   pem_key_path,
						   "killall python",
				)

		for mw_host in middleware_set:
			with warn_only():
				rsridhar_remote_exe_bash(username,
						   mw_host,
							pem_key_path,
						   "killall java",
			)
			with warn_only():
				# Kill dstat
				rsridhar_remote_exe_bash(username,
							   mw_host,
							   pem_key_path,
							   "killall python",
				)
		#DB
	# copy back log files
	# get dump messages

		rsridhar_remote_exe_bash(username,
				   db_host,
				   pem_key_path,
				   "/local/rsridhar/pgsql/bin/pg_dump message -p %s  -f /tmp/%s.sql" % (database_port, experiment_id),
		)
		# get it locally
		rsridhar_from_remote(username,
					   db_host,
					   pem_key_path,
					   "/tmp/%s.sql" % (experiment_id),
					   "%s" % directory,
		)
		#

		# enumerate in middlewares
		middleware_num = 1
		for mw_host in middleware_set:
			with warn_only():
				rsridhar_remote_exe_bash(username,
						   mw_host,
						   pem_key_path,
						   "mkdir /local/rsridhar/logs",
				)
				rsridhar_remote_exe_bash(username,
						   mw_host,
						   pem_key_path,
						   "mkdir middleware",
						   use_cwd='/local/rsridhar/%s' % experiment_id,
				)
				# Remove any stale log, if exists
				rsridhar_remote_exe_bash(username,
						   mw_host,
						   pem_key_path,
						   "rm /local/rsridhar/%s/middleware/*.log" % experiment_id,
				)
				# move logs to middleware folder
				rsridhar_remote_exe_bash(username,
						   mw_host,
						   pem_key_path,
						   "mv /tmp/rsridhar*.log* /local/rsridhar/%s/middleware/" % experiment_id,
				)
				# copy dstat
				rsridhar_remote_exe_bash(username,
						   mw_host,
						   pem_key_path,
						   "tar cvzf /local/rsridhar/logs/%s-middleware-logs.tgz  middleware" % (middleware_num),
						   use_cwd='/local/rsridhar/%s' % experiment_id,
				)
				rsridhar_from_remote(username,
							   mw_host,
							   pem_key_path,
							   "/local/rsridhar/logs/%s-middleware-logs.tgz" % middleware_num,
							   "%s/middleware-logs-%s.tgz" % (directory, middleware_num),
				)
				middleware_num += 1

		machine_num = 1

		for cl_host in client_set:
			with warn_only():
				#for each clien do:
				# for (machine_num1, cl_hos) in enumerate(cl_host):

				# make  clietn directory to store all logs
				rsridhar_remote_exe_bash(username,
						   cl_host,
						   pem_key_path,
						   "mkdir client",
						   use_cwd='/local/rsridhar/%s' % experiment_id,
				)
				# Remove any stale log, if exists
				rsridhar_remote_exe_bash(username,
						   cl_host,
						   pem_key_path,
						   "rm /local/rsridhar/%s/client/*.log" % experiment_id,
				)
				# move all log files to client directory
				rsridhar_remote_exe_bash(username,
						   cl_host,
						   pem_key_path,
						   "mv /tmp/rsridhar*.log* /local/rsridhar/%s/client/" % experiment_id,
				)
				# copy dstat log file from tmp/ to client

				rsridhar_remote_exe_bash(username,
						   cl_host,
						   pem_key_path,
						   "tar cvzf /local/rsridhar/logs/%s-%s-client-logs.tgz client" % (experiment_id, cl_host),
						   use_cwd='/local/rsridhar/%s' % experiment_id,
					)
				# move the zipped folder to the local machine and tada
				rsridhar_from_remote(username,
							   cl_host,
							   pem_key_path,
							   "/local/rsridhar/logs/%s-%s-client-logs.tgz" % (experiment_id, cl_host),
							   "%s/client-logs-%d.tgz" % (directory, machine_num),
				)
				machine_num += 1

	rsridhar_db_start_stop(username,
						 db_host,
						 pem_key_path,
						 "stop")

if __name__ == '__main__':
	main()























































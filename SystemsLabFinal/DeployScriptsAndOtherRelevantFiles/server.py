__author__ = 'ramapriyasridharan'
import os, pprint
import paramiko
from fabric.api import *
import time
import argparse
import ConfigParser


def rsridhar_install_remote_server_stuff(user_name, hostname, mw_jar_path, mw_prop_file_path, path_to_key, amazon_machine):
	env.user = user_name
	if path_to_key:
		env.key_filename = path_to_key
	env.host_string = hostname

	run('pwd')

	if amazon_machine:
		sudo('chown -R ec2-user:ec2-user /local')
		rsridhar_install_remote_stuff(user_name, hostname, path_to_key)
		rsridhar_install_java_remote(user_name, hostname, path_to_key)

	with warn_only():
		run('mkdir /local/rsridhar')

	# Copy jar to remote machine
	put(mw_jar_path, '/local/rsridhar')
	# Copy properties file to remote machine
	with warn_only():
		run('mkdir /local/rsridhar/properties')
	put(mw_prop_file_path, '/local/rsridhar/properties')
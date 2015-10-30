__author__ = 'ramapriyasridharan'
import os, pprint
import paramiko
from fabric.api import *
import time
import argparse
import ConfigParser

def rsridhar_install_remote_stuff(user_name, hostname, path_to_key=None):
	env.user = user_name
	if path_to_key:
		env.key_filename = path_to_key
		print user_name
		print path_to_key
	env.host_string = hostname

	sudo('yum install readline* -y')
	sudo('yum install zlib* -y')
	sudo('yum install gcc -y')
	sudo('yum install dstat -y')


#only for ec2
def rsridhar_install_java_remote(user_name, hostname, path_to_key=None):
	env.user = user_name
	if path_to_key:
		env.key_filename = path_to_key[0]
	env.host_string = hostname

	sudo('yum install java-1.7.0-openjdk -y')
	sudo('sudo alternatives --set java /usr/lib/jvm/jre-1.7.0-openjdk.x86_64/bin/java')
	sudo('chown -R ec2-user:ec2-user /local')
	#client properties

def rsridhar_remote_end_other_java(user_name, hostname, path_to_key):
	env.user = user_name
	if path_to_key:
		env.key_filename = path_to_key
	env.host_string = hostname

	with warn_only():
		run("pkill -f 'java -jar'")
		run("killall java")


def rsridhar_to_remote(user_name, hostname, path_to_key, source_jar, dest):
	env.user = user_name
	if path_to_key:
		env.key_filename = path_to_key
	env.host_string = hostname

	put(source_jar, dest)


def rsridhar_from_remote(user_name, hostname, path_to_key, remote_path, local_path):
	env.user = user_name
	if path_to_key:
		env.key_filename = path_to_key
	env.host_string = hostname

	get(remote_path, local_path)


def rsridhar_remote_exe_bash(user_name, hostname, path_to_key, command, use_cwd='/', pty=True):
	env.user = user_name
	if path_to_key:
		env.key_filename = path_to_key
	env.host_string = hostname

	with cd(use_cwd):
		res = run(command, pty=pty)
	return res
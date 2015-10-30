__author__ = 'ramapriyasridharan'
import os, pprint
import paramiko
from fabric.api import *
import time
import argparse
import ConfigParser


#for ec2 and dryad
def rsridhar_install_db_remote(user_name, db_port, hostname, sql_script_path, pg_hba_conf_path, rsridhar_conf_path,
				   rsridhar_db_path, amazon_machine, path_to_key, db_name):
	env.user = user_name
	if path_to_key:
		env.key_filename = path_to_key
	env.host_string = hostname

	if amazon_machine:
		sudo('chown -R ec2-user:ec2-user /local')

	with warn_only():
		run('mkdir /local/rsridhar')

	put(rsridhar_db_path, '/local/rsridhar/')
	with cd('/local/rsridhar'):
		run('tar xf postgresql-9.3.1.tar.gz')
		run('mv postgresql-9.3.1 pgsql')

	with cd('/local/rsridhar/pgsql'):
		run('./configure --prefix=/local/rsridhar/pgsql')
		run('make')
		run('make install')

	with cd('/local/rsridhar/pgsql'):
		with warn_only():
			run('mkdir data')
		run('bin/initdb /local/rsridhar/pgsql/data')

	put(pg_hba_conf_path, '/local/rsridhar/pgsql/data/pg_hba.conf')
	put(rsridhar_conf_path, '/local/rsridhar/pgsql/data/postgresql.conf')
	put(sql_script_path, '/local/rsridhar/create_schema.sql')

	with cd('/local/rsridhar/pgsql'):
		run('bin/pg_ctl -D /local/rsridhar/pgsql/data -l logfile start &', pty=False)
		time.sleep(5)
		run('bin/createdb -p %s %s' % (db_port, db_name))
		run('bin/psql -p %s  -f ../create_schema.sql %s' % (db_port, db_name))

		# restart and recreate schema


def rsridhar_install_db_remote_again(user_name, db_port, hostname, sql_script_path, path_to_key, db_name):
	env.user = user_name
	if path_to_key:
		env.key_filename = path_to_key
	env.host_string = hostname

	with cd('/local/rsridhar/pgsql'):
		run('bin/dropdb -p %s %s' % (db_port, db_name))
		run('bin/createdb -p %s %s' % (db_port, db_name))
		run('bin/psql -p %s -f ../create_schema.sql %s' % (db_port, db_name))

		# start/stop db


def rsridhar_db_start_stop(user_name, hostname, path_to_key, operation):
	env.user = user_name
	if path_to_key:
		env.key_filename = path_to_key
	env.host_string = hostname

	if operation not in ["start", "stop", "restart"]:
		sys.exit("Supported operations for postgres service: start, stop, restart")

	with cd('/local/rsridhar/pgsql'):
		run('bin/pg_ctl -D /local/rsridhar/pgsql/data -l logfile %s &' % operation, pty=False)

import os, pprint
import paramiko
from fabric.api import *
import time
import argparse
import ConfigParser

#only for ec2
# Script based on this tutorial http://www.linuxjournal.com/content/fabric-system-administrators-best-friend
def install_basic_utils(user_name, hostname, path_to_key=None):
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
def setup_java_env(user_name, hostname, path_to_key=None):
    env.user = user_name
    if path_to_key:
        env.key_filename = path_to_key[0]
    env.host_string = hostname

    sudo('yum install java-1.7.0-openjdk -y')
    sudo('sudo alternatives --set java /usr/lib/jvm/jre-1.7.0-openjdk.x86_64/bin/java')
    sudo('chown -R ec2-user:ec2-user /local')


#for ec2 and dryad
def setup_postgres(user_name, db_port, hostname, sql_script_path, pg_hba_conf_path, postgres_conf_path,
                   postgres_source_path, is_ec2, path_to_key, db_name):
    env.user = user_name
    if path_to_key:
        env.key_filename = path_to_key
    env.host_string = hostname

    if is_ec2:
        sudo('chown -R ec2-user:ec2-user /local')

    with warn_only():
        run('mkdir /local/rsridhar')

    put(postgres_source_path, '/local/rsridhar/')
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
    put(postgres_conf_path, '/local/rsridhar/pgsql/data/postgresql.conf')
    put(sql_script_path, '/local/rsridhar/create_schema.sql')

    with cd('/local/rsridhar/pgsql'):
        run('bin/pg_ctl -D /local/rsridhar/pgsql/data -l logfile start &', pty=False)
        time.sleep(5)
        run('bin/createdb -p %s %s' % (db_port, db_name))
        run('bin/psql -p %s  -f ../create_schema.sql %s' % (db_port, db_name))

        # restart and recreate schema


def reconstructdb(user_name, db_port, hostname, sql_script_path, path_to_key, db_name):
    env.user = user_name
    if path_to_key:
        env.key_filename = path_to_key
    env.host_string = hostname

    with cd('/local/rsridhar/pgsql'):
        run('bin/dropdb -p %s %s' % (db_port, db_name))
        run('bin/createdb -p %s %s' % (db_port, db_name))
        run('bin/psql -p %s -f ../create_schema.sql %s' % (db_port, db_name))

        # start/stop db


def postgres_service_cmd(user_name, hostname, path_to_key, operation):
    env.user = user_name
    if path_to_key:
        env.key_filename = path_to_key
    env.host_string = hostname

    if operation not in ["start", "stop", "restart"]:
        sys.exit("Supported operations for postgres service: start, stop, restart")

    with cd('/local/rsridhar/pgsql'):
        run('bin/pg_ctl -D /local/rsridhar/pgsql/data -l logfile %s &' % operation, pty=False)


        #setup middleware


def setup_middleware_env(user_name, hostname, mw_jar_path, mw_prop_file_path, path_to_key, is_ec2):
    env.user = user_name
    if path_to_key:
        env.key_filename = path_to_key
    env.host_string = hostname

    run('pwd')

    if is_ec2:
        sudo('chown -R ec2-user:ec2-user /local')
        install_basic_utils(user_name, hostname, path_to_key)
        setup_java_env(user_name, hostname, path_to_key)

    with warn_only():
        run('mkdir /local/rsridhar')

    # Copy jar to remote machine
    put(mw_jar_path, '/local/rsridhar')
    # Copy properties file to remote machine
    with warn_only():
        run('mkdir /local/rsridhar/properties')
    put(mw_prop_file_path, '/local/rsridhar/properties')

    #client properties


def setup_client_env(user_name, hostname, client_jar_path, client_prop_file_path, path_to_key, is_ec2):
    env.user = user_name
    if path_to_key:
        env.key_filename = path_to_key
    env.host_string = hostname

    if is_ec2:
        sudo('chown -R ec2-user:ec2-user /local')
        install_basic_utils(user_name, hostname, path_to_key)
        setup_java_env(user_name, hostname, path_to_key)

    with warn_only():
        run('mkdir /local/rsridhar')

    # Copy jar to remote machine
    put(client_jar_path, '/local/rsridhar')
    # Copy properties file to remote machine
    with warn_only():
        run('mkdir /local/rsridhar/properties')
    put(client_prop_file_path, '/local/rsridhar/properties')


    # kill all java programs on machine


def kill_java_processes(user_name, hostname, path_to_key):
    env.user = user_name
    if path_to_key:
        env.key_filename = path_to_key
    env.host_string = hostname

    with warn_only():
        run("pkill -f 'java -jar'")
        run("killall java")


def copy_file_to_host(user_name, hostname, path_to_key, source_jar, dest):
    env.user = user_name
    if path_to_key:
        env.key_filename = path_to_key
    env.host_string = hostname

    put(source_jar, dest)


def get_file_from_host(user_name, hostname, path_to_key, remote_path, local_path):
    env.user = user_name
    if path_to_key:
        env.key_filename = path_to_key
    env.host_string = hostname

    get(remote_path, local_path)


def run_remote_cmd(user_name, hostname, path_to_key, command, use_cwd='/', pty=True):
    env.user = user_name
    if path_to_key:
        env.key_filename = path_to_key
    env.host_string = hostname

    with cd(use_cwd):
        res = run(command, pty=pty)
    return res


def run_remote_sudo_cmd(user_name, hostname, path_to_key, command):
    env.user = user_name
    if path_to_key:
        env.key_filename = path_to_key
    env.host_string = hostname

    res = sudo(command)
    return res


def execute_jar_on_host(user_name, hostname, path_to_key, jar_path, java_path, background=False, use_cwd='/',
                        cmd_args=''):
    env.user = user_name
    if path_to_key:
        env.key_filename = path_to_key
    env.host_string = hostname

    with cd(use_cwd):
        if background:
            run("%s -jar %s %s &" % (java_path, jar_path, cmd_args), shell=False)
        else:
            run("%s -jar %s %s" % (java_path, jar_path, cmd_args))


def main():
    '''
    Enter the experiment .ini file path
    '''
    parser = argparse.ArgumentParser()
    parser.add_argument("experimentlist", help="the experiment file path")
    #parser.add_argument("--skipdbinstall", action="store_true")
    args = parser.parse_args()

    # experimentlist is a .ini file location
    # Read it
    exp_list = []
    #has list of experiment paths
    with open(args.experimentlist) as f:
        for line in f:
            line = line.strip()
            exp_list.append(line)

    print exp_list

    # config files have almost same setup
    config = ConfigParser.ConfigParser()
    config.read(exp_list[0])

    # DB_HOST
    db_host = config.get("middleware_props", "dbservername")

    ##########################################################
    ##########################################################
    ### START EXP SETUP ######################################
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



    #middleware_jar_name = configFile.get("paths","middleware_jar").split('/')[-1]

    mw_cl_map = {}
    for mw, cl in config.items("mapping"):
            item_list = cl.split(',')
            for item in item_list:
                mw_cl_map[item] = mw

    database_port = config.get("middleware_props", "dbport")

    # DB
    # Now setup db engine
    # Need to first install postgres-9.4.0 on dryad
    # java already installed



    if config.get("setup","is_ec2") in ["True","true"]:
        pem_key_path = config.get("paths","pem_key_path")
        install_basic_utils(config.get("setup", "username"), # ec2-user or torekond
                          db_host,
                          config.get("paths", "pem_key_path"),
                          )
    else:
        pem_key_path=None
    setup_postgres(config.get("setup", "username"),
                   database_port,
                   db_host,
                   config.get("paths", "db_schema_path"),
                   config.get("paths", "pg_hba_conf_path"),
                   config.get("paths", "postgres_conf_path"),
                   config.get("paths", "postgres_source_path"),
                   False,
                   pem_key_path,
                   config.get("middleware_props", "dbdatabasename")
    )
    experiment_id = config.get("experiment", "id")
    directory = config.get("experiment", "output_dir")

    if config.get("setup","is_ec2") in ["True","true"]:
        java_path = config.get("constants","ec2_java7_path")
    else:
        java_path = config.get("constants", "dryad_java7_path")
    username = config.get("setup", "username")

    if config.get("setup", "is_ec2") in ["True", "true"]: # If host is on EC2 install gcc, etc.
            for mw_host in middleware_set:
                install_basic_utils(config.get("setup", "username"), # ec2-user or torekond
                      mw_host,
                      config.get("paths", "pem_key_path"),
                      )
                setup_java_env(config.get("setup", "username"), # ec2-user or torekond
                      mw_host,
                      config.get("paths", "pem_key_path"),
                      )


    # 3. Set up Client machine
    # 3.a. Install necessary applications

    if config.get("setup", "is_ec2") in ["True", "true"]: # If host is on EC2 install gcc, etc.
            for cl_host in client_set:
                install_basic_utils(config.get("setup", "username"), # ec2-user or torekond
                      cl_host,
                      config.get("paths", "pem_key_path"),
                      )
                setup_java_env(config.get("setup", "username"), # ec2-user or torekond
                      cl_host,
                      config.get("paths", "pem_key_path"),
                      )

    for experiment in exp_list:
        # initialize all middlewares
        # assume java already installed
        #make middleware-client mapping
        # a map with clinet gives middleware

        configFile = ConfigParser.ConfigParser()
        configFile.read(experiment)
        experiment_id = configFile.get("experiment", "id")
        directory = configFile.get("experiment", "output_dir")


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
            run_remote_cmd(username,
                       mw_host,
                       pem_key_path,
                       "mkdir -p /local/rsridhar/%s/properties" % experiment_id)

            with warn_only():
                run_remote_cmd(username,
                           mw_host,
                           pem_key_path,
                           args.experimentlist,
                           "mkdir -p /local/rsridhar/logs")

            copy_file_to_host(username,
                          mw_host,
                          pem_key_path,
                          args.experimentlist,
                          "/local/rsridhar/%s" % experiment_id)

            '''run_remote_cmd(username,
                           mw_host,
                           pem_key_path,
                           "killall java")'''



        # now setup client machine
        # java already installed
        for cl_host in client_set:
            print cl_host
            run_remote_cmd(username,
                       cl_host,
                       pem_key_path,
                       "mkdir -p /local/rsridhar/%s/properties" % experiment_id)
            with warn_only():
                run_remote_cmd(username,
                           cl_host,
                           pem_key_path,
                           "mkdir -p /local/rsridhar/logs")

            copy_file_to_host(username,
                          cl_host,
                          pem_key_path,
                          args.experimentlist,
                          "/local/rsridhar/%s" % experiment_id)





        # Clean start DB
        #kill server process before db start


        postgres_service_cmd(username,
                         db_host,
                         pem_key_path,
                         "start")
        # Recreate DB
        reconstructdb(username,
                  database_port,
                  db_host,
                  configFile.get("paths", "db_schema_path"),
                  pem_key_path,
                  configFile.get("middleware_props", "dbdatabasename"))


        # Move middleware jar to middleware
        for mw_host in middleware_set:
            copy_file_to_host(username,
                          mw_host,
                          pem_key_path,
                          configFile.get("paths", "middleware_jar"),
                          "/local/rsridhar/%s/server.jar" % experiment_id)

            # create middleware property file
            # for each middleware and
            # place them under properties folder

            # create this file
            prop_file_on_local_machine_S = '%s/middleware.properties' % directory
            with open(prop_file_on_local_machine_S, 'w') as f:
                f.write("serverhost=%s\n" % mw_host)
                # f.write("buffer_size=%s \n"%configFile.get("client_cl_args","message_size"))
                for keys in configFile.options("middleware_props"):
                    f.write("%s=%s\n" % (keys, configFile.get("middleware_props", keys)))

            copy_file_to_host(configFile.get("setup", "username"),
                          mw_host,
                          pem_key_path,
                          prop_file_on_local_machine_S,
                          "/local/rsridhar/%s/properties" % experiment_id)

        for cl_host in client_set:
            # move client jars to client host
            copy_file_to_host(username,
                          cl_host,
                          pem_key_path,
                          configFile.get("paths", "client_jar"),
                          "/local/rsridhar/%s/client.jar" % experiment_id)


            # copy properties file
            prop_file_on_local_machine_C = "%s/client.properties" % directory
            with open(prop_file_on_local_machine_C, "w") as fc:
                fc.write("serverhost=%s\n" % mw_cl_map[cl_host])
                #fc.write("middleware_url=%s \n" % mw_host)
                for keys in configFile.options("client_props"):
                    fc.write("%s=%s\n" % (keys, configFile.get("client_props", keys)))

                    # copy files to host
            copy_file_to_host(username,
                          cl_host,
                          pem_key_path,
                          prop_file_on_local_machine_C,
                          "/local/rsridhar/%s/properties" % experiment_id)

    ####################################################
    ################# START EXPERIMENT
    ####################################################

        # start screen on db
        '''run_remote_cmd(username,
                       db_host,
                       pem_key_path,
                       "screen -S dstat -X stuff 'dstat --output /tmp/dstat-db-%s.log'`echo -ne '\015'`" % (experiment_id)
            )'''

        ######################
        #start middleware
        middle_jar_path = "/local/rsridhar/%s/server.jar" % experiment_id
        # usually no command arguments from middleware
        cmd_args = ''
        for option in configFile.options('middleware_cl_args'):
            cmd_args += ' %s ' % (option, configFile.get('middleware_cl_args', option))
        middle_command = "%s -jar %s %s 2>%s.err" % (java_path, middle_jar_path, cmd_args, experiment_id)

        #kill existing java processes on server

        for mw_host in middleware_set:
            with warn_only():
                kill_java_processes(configFile.get("setup", "username"),
                            mw_host,
                            pem_key_path)
        # on clien
        for cl_host in client_set:
            with warn_only():
                kill_java_processes(configFile.get("setup", "username"),
                            cl_host,
                            pem_key_path)

        # for each host: of middleware
        bshf = open('/tmp/run.sh', 'w')
        bshf.write('#!/bin/bash\n')
        bshf.write(middle_command)
        bshf.close()

        for mw_host in middleware_set:
            copy_file_to_host(username,
                          mw_host,
                          pem_key_path,
                          '/tmp/run.sh',
                          "/local/rsridhar/%s/run.sh" % experiment_id
            )

            with warn_only():
                run_remote_cmd(username,
                           mw_host,
                           pem_key_path,
                           "rm /tmp/rsrid*",
                           use_cwd='/local/rsridhar/%s' % experiment_id
                )

            '''run_remote_cmd(username,
                           mw_host,
                           pem_key_path,
                           "screen -S dstat -X stuff 'dstat -Tnmc --output /tmp/dstat-mw-%s.log'`echo -ne '\015'`" % (
                               experiment_id),
                           use_cwd='/local/rsridhar/%s' % exp_id
                )'''

            run_remote_cmd(username,
                       mw_host,
                       pem_key_path,
                       "chmod 777 run.sh",
                       use_cwd='/local/rsridhar/%s' % experiment_id
            )
            run_remote_cmd(username,
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
            for option in configFile.options("client_cl_args"):
                cmd_args += ' %s ' % (configFile.get("client_cl_args", option))

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

            copy_file_to_host(username,
                          cl_host,
                          pem_key_path,
                          '/tmp/clientrun.sh',
                          "/local/rsridhar/%s/clientrun.sh" % experiment_id)

            with warn_only():
                run_remote_cmd(username,
                           cl_host,
                           pem_key_path,
                           "rm /tmp/rsrid*",
                           use_cwd='/local/rsridhar/%s' % experiment_id
                )

                '''run_remote_cmd(username,
                               cl_host,
                               pem_key_path,
                               "screen -S dstat -X stuff 'dstat -Tnmc --output /tmp/dstat-mw-%s.log'`echo -ne '\015'`" % (
                                   experiment_id),
                               use_cwd='/local/rsridhar/%s' % exp_id
                    )'''
                run_remote_cmd(username,
                           cl_host,
                           pem_key_path,
                           "chmod 777 clientrun.sh",
                           use_cwd='/local/rsridhar/%s' % experiment_id
                )
                run_remote_cmd(username,
                           cl_host,
                           pem_key_path,
                           "screen -S client2 -d -m ./clientrun.sh; sleep 1",
                           use_cwd='/local/rsridhar/%s' % experiment_id
                )


        #############################
        # wait for execution to complete
        sleep_time_secs = int(configFile.get("client_cl_args", "duration"))
        print 'sleeping for %d secs' % sleep_time_secs
        time.sleep(sleep_time_secs)
        print ' completed sleep. '
        time.sleep(20)


        #Breakdown everything
        for cl_host in client_set:
            with warn_only():
                run_remote_cmd(username,
                           cl_host,
                           pem_key_path,
                           "killall java",
                )
                run_remote_cmd(username,
                           cl_host,
                           pem_key_path,
                           "killall python",
                )

        for mw_host in middleware_set:
            with warn_only():
                run_remote_cmd(username,
                           mw_host,
                            pem_key_path,
                           "killall java",
            )
            with warn_only():
                # Kill dstat
                run_remote_cmd(username,
                               mw_host,
                               pem_key_path,
                               "killall python",
                )
        #DB

        '''with warn_only():
            # Kill dstat on Database
            run_remote_cmd(username,
                           db_host,
                           None,
                           "killall python",
            )'''


    # copy back log files
    # get dump messages

        run_remote_cmd(username,
                   db_host,
                   pem_key_path,
                   "/local/rsridhar/pgsql/bin/pg_dump message -p %s  -f /tmp/%s.sql" % (database_port, experiment_id),
        )
        # get it locally
        get_file_from_host(username,
                       db_host,
                       pem_key_path,
                       "/tmp/%s.sql" % (experiment_id),
                       "%s" % directory,
        )
        #
        '''run_remote_cmd(username,
                       db_host,
                       pem_key_path,
                       "mv /tmp/dstat-db-%s.log /local/rsridhar/" % (experiment_id),
            )

            get_file_from_host(setup_username,
                           db_host,
                           pem_key_path,
                           "/local/rsridhar/dstat-db-%s.log" % exp_id,
                           "%s/dstat-db.log" % (exp_output_dir),
            )'''



        # enumerate in middlewares
        middleware_num = 1
        for mw_host in middleware_set:
            with warn_only():
                run_remote_cmd(username,
                           mw_host,
                           pem_key_path,
                           "mkdir /local/rsridhar/logs",
                )
                run_remote_cmd(username,
                           mw_host,
                           pem_key_path,
                           "mkdir middleware",
                           use_cwd='/local/rsridhar/%s' % experiment_id,
                )
                # Remove any stale log, if exists
                run_remote_cmd(username,
                           mw_host,
                           pem_key_path,
                           "rm /local/rsridhar/%s/middleware/*.log" % experiment_id,
                )
                # move logs to middleware folder
                run_remote_cmd(username,
                           mw_host,
                           pem_key_path,
                           "mv /tmp/rsridhar*.log* /local/rsridhar/%s/middleware/" % experiment_id,
                )
                # copy dstat
                '''run_remote_cmd(username,
                               mw_host,
                               None,
                               "cp /tmp/dstat-mw-%s.log /local/rsridhar/%s/middleware/" % (experiment_id, experiment_id),
                 )'''

                run_remote_cmd(username,
                           mw_host,
                           pem_key_path,
                           "tar cvzf /local/rsridhar/logs/%s-middleware-logs.tgz  middleware" % (middleware_num),
                           use_cwd='/local/rsridhar/%s' % experiment_id,
                )
                get_file_from_host(username,
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
                run_remote_cmd(username,
                           cl_host,
                           pem_key_path,
                           "mkdir client",
                           use_cwd='/local/rsridhar/%s' % experiment_id,
                )
                # Remove any stale log, if exists
                run_remote_cmd(username,
                           cl_host,
                           pem_key_path,
                           "rm /local/rsridhar/%s/client/*.log" % experiment_id,
                )
                # move all log files to client directory
                run_remote_cmd(username,
                           cl_host,
                           pem_key_path,
                           "mv /tmp/rsridhar*.log* /local/rsridhar/%s/client/" % experiment_id,
                )
                # copy dstat log file from tmp/ to client
                '''run_remote_cmd(username,
                               mw_host,
                               None,
                               "cp /tmp/dstat-%s.log /local/rsridhar/%s/client/" % (experiment_id, experiment_id),
                )
                '''

                run_remote_cmd(username,
                           cl_host,
                           pem_key_path,
                           "tar cvzf /local/rsridhar/logs/%s-%s-client-logs.tgz client" % (experiment_id, cl_host),
                           use_cwd='/local/rsridhar/%s' % experiment_id,
                    )
                # move the zipped folder to the local machine and tada
                get_file_from_host(username,
                               cl_host,
                               pem_key_path,
                               "/local/rsridhar/logs/%s-%s-client-logs.tgz" % (experiment_id, cl_host),
                               "%s/client-logs-%d.tgz" % (directory, machine_num),
                )
                machine_num += 1

    postgres_service_cmd(username,
                         db_host,
                         pem_key_path,
                         "stop")

if __name__ == '__main__':
    main()














        
      
                
     
    
    
    
    
    
    
    
        
        
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
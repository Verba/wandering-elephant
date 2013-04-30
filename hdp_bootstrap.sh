#!/usr/bin/env bash
# Sets up a fresh CentOS 6 box to run Hadoop (HDP 1.2 from Hortonworks).

# Set up nameservers.
# http://ithelpblog.com/os/linux/redhat/centos-redhat/howto-fix-couldnt-resolve-host-on-centos-redhat-rhel-fedora/
# http://stackoverflow.com/a/850731/1486325
echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf

### Update packages. ###
sudo yum --assumeyes update

### Install Java ###
# http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap1-2.html#rpm-chap1-2-5
# HDP says it wants Oracle JDK 1.6; I say too bad.
sudo yum --assumeyes install java-1.7.0-openjdk.x86_64
echo "export JAVA_HOME=/usr/lib/jvm/java-1.7.0" > ~/.bashrc
source ~/.bashrc

# Symlink java where Hadoop will look for it.
sudo mkdir /usr/java
sudo ln -s /usr/lib/jvm/java-1.7.0 /usr/java/default

### Set up Hortonworks package repositories. ###
# http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap1-3.html
sudo wget -nv http://public-repo-1.hortonworks.com/HDP/centos6/1.x/updates/1.2.1/hdp.repo -O /etc/yum.repos.d/hdp.repo
sudo wget -nv http://public-repo-1.hortonworks.com/ambari/centos5/1.x/updates/1.2.2.4/ambari.repo -O /etc/yum.repos.d/ambari.repo

### Set up users and groups. ###
# http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap1-11-1.html
# http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap1-10.html
source /vagrant/hadoop_user_vars.sh

sudo useradd $HDFS_USER
sudo useradd $MAPRED_USER
sudo useradd $PIG_USER
sudo useradd $OOZIE_USER
sudo useradd $HIVE_USER
sudo useradd $WEBHCAT_USER
sudo useradd $HBASE_USER
sudo useradd $ZOOKEEPER_USER
sudo groupadd $HADOOP_GROUP

### Set up directories. ###
# http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap1-11-2.html
# http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap1-10.html
source /vagrant/hadoop_dir_vars.sh

### Set default permissions. ###
# http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap2-1.html
umask 0022

### Install Hadoop RPMs ###
# http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap2-2.html
sudo yum --assumeyes install hadoop hadoop-libhdfs hadoop-native hadoop-pipes hadoop-sbin openssl

### Install compression libraries. ###
# http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap2-3.html
sudo yum --assumeyes install snappy snappy-devel
sudo ln -sf /usr/lib64/libsnappy.so /usr/lib/hadoop/lib/native/Linux-amd64-64/.
sudo yum --assumeyes install hadoop-lzo lzo lzo-devel hadoop-lzo-native

### Create directories. ###
# http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap2-4.html

# Create NameNode directories.
sudo mkdir -p $DFS_NAME_DIR
sudo chown -R $HDFS_USER:$HADOOP_GROUP $DFS_NAME_DIR
sudo chmod -R 755 $DFS_NAME_DIR

# Create SecondaryNameNode directories.
sudo mkdir -p $FS_CHECKPOINT_DIR
sudo chown -R $HDFS_USER:$HADOOP_GROUP $FS_CHECKPOINT_DIR
sudo chmod -R 755 $FS_CHECKPOINT_DIR

# Create DataNode and MapReduce local directories.
sudo mkdir -p $DFS_DATA_DIR
sudo chown -R $HDFS_USER:$HADOOP_GROUP $DFS_DATA_DIR
sudo chmod -R 750 $DFS_DATA_DIR

sudo mkdir -p $MAPREDUCE_LOCAL_DIR
sudo chown -R $MAPRED_USER:$HADOOP_GROUP $MAPREDUCE_LOCAL_DIR
sudo chmod -R 755 $MAPREDUCE_LOCAL_DIR

# Create Log and PID directories.
sudo mkdir -p $HDFS_LOG_DIR
sudo chown -R $HDFS_USER:$HADOOP_GROUP $HDFS_LOG_DIR
sudo chmod -R 755 $HDFS_LOG_DIR

sudo mkdir -p $MAPRED_LOG_DIR
sudo chown -R $MAPRED_USER:$HADOOP_GROUP $MAPRED_LOG_DIR
sudo chmod -R 755 $MAPRED_LOG_DIR

sudo mkdir -p $HDFS_PID_DIR
sudo chown -R $HDFS_USER:$HADOOP_GROUP $HDFS_PID_DIR
sudo chmod -R 755 $HDFS_PID_DIR

sudo mkdir -p $MAPRED_PID_DIR
sudo chown -R $MAPRED_USER:$HADOOP_GROUP $MAPRED_PID_DIR
sudo chmod -R 755 $MAPRED_PID_DIR

### Set up Hadoop configuration files. ###
# http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm_chap3.html

# Tabula rasa.
sudo rm -rf $HADOOP_CONF_DIR
sudo mkdir -p $HADOOP_CONF_DIR

# NOTE: Files in /vagrant/hadoop_config have been manually configured.
sudo cp /vagrant/hadoop_config/* $HADOOP_CONF_DIR/
sudo chmod a+x $HADOOP_CONF_DIR/
sudo chown -R $HDFS_USER:$HADOOP_GROUP $HADOOP_CONF_DIR/../
sudo chmod -R 755 $HADOOP_CONF_DIR/../

### Initialize Hadoop and test it. ###
# http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap4.html
sudo -u $HDFS_USER /usr/lib/hadoop/bin/hadoop namenode -format -nonInteractive -force
sudo -u $HDFS_USER /usr/lib/hadoop/bin/hadoop-daemon.sh --config $HADOOP_CONF_DIR start namenode
sudo -u $HDFS_USER /usr/lib/hadoop/bin/hadoop-daemon.sh --config $HADOOP_CONF_DIR start secondarynamenode
sudo -u $HDFS_USER /usr/lib/hadoop/bin/hadoop-daemon.sh --config $HADOOP_CONF_DIR start datanode
sudo -u $HDFS_USER /usr/lib/hadoop/bin/hadoop fs -mkdir /mapred
sudo -u $HDFS_USER /usr/lib/hadoop/bin/hadoop fs -chown -R mapred /mapred

sudo -u $MAPRED_USER /usr/lib/hadoop/bin/hadoop-daemon.sh --config $HADOOP_CONF_DIR start jobtracker
sudo -u $MAPRED_USER /usr/lib/hadoop/bin/hadoop-daemon.sh --config $HADOOP_CONF_DIR start historyserver
sudo -u $MAPRED_USER /usr/lib/hadoop/bin/hadoop-daemon.sh --config $HADOOP_CONF_DIR start tasktracker

# Run smoketest.
sudo -u $HDFS_USER /usr/lib/hadoop/bin/hadoop jar /usr/lib/hadoop/hadoop-examples.jar teragen 100000 /test/100msort/input
sudo -u $HDFS_USER /usr/lib/hadoop/bin/hadoop jar /usr/lib/hadoop/hadoop-examples.jar terasort /test/100msort/input /test/100msort/output


### Install extras. ###
for script in /vagrant/install/*.sh; do
  $script
done


#!/bin/sh

top=$PWD

if [ $# != 1 ]; then
	cmd=`basename $0`
	echo -e "usage: $cmd <hadoop>\n"
	exit 1
fi

if [ -z "$JAVA_HOME" ]; then
	echo -e "JAVA_HOME not set!\n"
	exit 1
fi

tarball=$1

hadoop=`basename $1`
hadoop=${hadoop%%.tar.*}

cd /opt
echo "extracting $hadoop ..."
# FIXME
rm -rf $hadoop /tmp/hadoop-$USER
tar xf $tarball || exit 1

cd $hadoop
sed -i "s:export JAVA_HOME=\${JAVA_HOME}:export JAVA_HOME=${JAVA_HOME}:" etc/hadoop/hadoop-env.sh

bin/hadoop version || exit 1
echo

mkdir -p tmp hdfs hdfs/data hdfs/name

### HDFS ###
patch -p1 < $top/configuration.patch || exit 1

bin/hdfs namenode -format

sbin/start-dfs.sh

firefox http://localhost:50070

bin/hdfs dfs -mkdir /user
bin/hdfs dfs -mkdir /user/$USER

bin/hdfs dfs -put etc/hadoop input

bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.1.jar grep input output 'dfs[a-z.]+'

bin/hdfs dfs -get output output
cat output/*

bin/hdfs dfs -cat output/*

# sbin/stop-dfs.sh
echo "***************************"
echo "   run 'sbin/stop-dfs.sh'"
echo "***************************"
echo

### YARN ###
cp -v etc/hadoop/mapred-site.xml{.template,}
patch -p1 < $top/mapred-and-yarn.patch || exit 1

sbin/start-yarn.sh

firefox http://localhost:8088
# do somehting more here

# sbin/stop-yarn.sh
echo "***************************"
echo "    run 'sbin/stop-yarn.sh'"
echo "***************************"
echo

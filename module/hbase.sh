function hbase_deploy
{
	sed -i "s:# export JAVA_HOME=.*:export JAVA_HOME=${JAVA_HOME}:" conf/hbase-env.sh

	temp=`mktemp`

	cat > $temp << EOF
  <property>
    <name>hbase.cluster.distributed</name>
    <value>true</value>
  </property>
  <property>
    <name>hbase.rootdir</name>
    <value>hdfs://$master:9000/hbase</value>
  </property>
  <property>
    <name>hbase.zookeeper.property.dataDir</name>
    <value>$data_root/zookeeper</value>
  </property>
EOF

	if [ $mode = 'cluster' ]; then
		quorum=`echo ${hosts[@]} | sed 's/\s\+/,/g'`
		cat >> $temp << EOF
  <property>
    <name>hbase.zookeeper.quorum</name>
    <value>$quorum</value>
  </property>
EOF
	fi

	sed -i "/<configuration>/r $temp" conf/hbase-site.xml

	rm -f $temp

	add_env HBASE_HOME $PWD
	add_path '$HBASE_HOME/bin'

	if [ $mode = 'cluster' ]; then
		truncate --size 0 conf/regionservers
		local count
		for ((count = 1; count < ${#hosts[@]}; count++))
		do
			echo ${hosts[$count]} >> conf/regionservers
		done

		echo ${hosts[1]} > conf/backup-masters
	fi

	echo "region servers:"
	cat conf/regionservers
	echo

	echo "backup masters:"
	cat conf/backup-masters
	echo
}

function hbase_destroy
{
	sed -i '/HBASE_HOME/d' $profile
}
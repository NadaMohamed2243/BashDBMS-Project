#!/bin/bash

function createDBI {
        echo "---- creating a database ----- "
        read -p "Enter the name of the database : " DBname ;
	DBname=$(echo "$DBname" | tr -d '[:space:]')
        checkRegex $DBname;
}

function selectDB {
	echo "----Selecting a database ----- "
	select dir in */; do
			cd $dir
			echo $PWD
			echo "$dir"
	done 
}

function checkRegex {
	if [[ $1 =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
		echo "$1 is a Valid database name."
		if [ -d $1 ];then
			echo "The database is found"
		else 
			mkdir $1;
			echo "the database $1 is created successfully"
		fi

        else
                echo "Invalid database name. Please use only letters, numbers, and underscores, and start with a letter or underscore."
      
         fi
}


if [ -d "Database" ];then
	echo "The dir is found"
	cd Database
	echo "database directory : "
	echo "choose from the following :"

	select choice in "create Database" "list databases" "Connect to databases" "Drop databases"
	do
		case $choice in 
 			"create Database") echo "create"; createDBI;             		
				;;
			"list databases") echo "list"; selectDB;
				;;
			"Connect to databases") echo "connect"
				;;
			"Drop databases") echo "drop"
				;;
			*) echo "not exist choose again"
				;;
		esac
	done
else
	echo "The dir not found"
	mkdir Database
fi










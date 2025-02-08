#!/bin/bash

DELIMITER=","

function checkRegex {
    if [[ $1 =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        echo "$1 is a valid database name."
        if [ -d $1 ]; then
            echo "The database is found."
        else 
            mkdir $1
            echo "The database $1 is created successfully."
        fi
    else
        echo "Invalid database name. Please use only letters, numbers, and underscores, and start with a letter or underscore."
    fi
}

function createDBI {
    echo "---- Creating a database -----"
    read -p "Enter the name of the database: " DBname
    DBname=$(echo "$DBname" | tr -d '[:space:]')
    checkRegex $DBname
}

function selectDB {
    echo "---- Selecting a database -----"
    select dir in */; do
        if [ -d "$dir" ]; then
            cd "$dir" || exit
            echo "You are now in the database: $dir"
            tableMenu  
            break  
        else
            echo "Invalid choice. Please choose a valid directory."
        fi
    done
}

function mainMenu {
    echo "---- Main Menu -----"
    select choice in "Create Database" "List Databases" "Connect to Database" "Drop Database"; do
        case $choice in
            "Create Database") 
                createDBI
                mainMenu ;;
            "List Databases") 
                listDatabases
                mainMenu ;;
            "Connect to Database") 
                selectDB
                mainMenu ;;
            "Drop Database") 
                dropDatabase
                mainMenu ;;
            *) 
                echo "Invalid choice, please try again."
                mainMenu ;;
        esac
    done
}


function listDatabases {
    echo "Databases:"
    ls -d */
}

function dropDatabase {
    listDatabases
    read -p "Enter the database name to drop: " DBname
    if [ -d "$DBname" ]; then
        rm -rf "$DBname"
        echo "Database '$DBname' dropped successfully."
    else
        echo "Database '$DBname' does not exist."
    fi
}



#----------------------------Menu PART

function tableMenu {
    while true; do
        echo "---- Table Menu -----"
        echo "1. Create Table"
        echo "2. List Tables"
        echo "3. Drop Table"
        echo "4. Insert into Table"
        echo "5. Select From Table"
        echo "6. Delete From Table"
        echo "7. Update Table"
        echo "8. Back to Main Menu"
        read -p "Enter your choice: " choice
        case $choice in
            1) createTable ;;
            2) listTables ;;
            3) dropTable ;;
            4) insertIntoTable ;;
            5) selectFromTable ;;
            6) deleteFromTable ;;
            7) updateTable ;;
            8) cd ..; break ;;
            *) echo "Invalid choice. Please try again." ;;
        esac
    done
}


function createTable {
    read -p "Enter table name: " tablename
    if [[ ! "$tablename" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        echo "Invalid table name. Use only letters, numbers, and underscores."
        return
    fi
    if [ -d "$tablename" ]; then
        echo "Table already exists."
    else
        mkdir "$tablename"
        touch "$tablename/metadata" "$tablename/data"
        echo "Table '$tablename' created successfully."

        read -p "Enter columns (e.g., id:int,name:str,age:int): " columns
        read -p "Enter primary key column: " primaryKey

        # Save metadata
        echo "$columns,primary:$primaryKey" > "$tablename/metadata"
        echo "Metadata saved successfully."
    fi
}


function listTables {
    echo "Tables:"
    ls -1
}

function dropTable {
    listTables
    read -p "Enter table name to drop: " tablename
    if [ -d "$tablename" ]; then
        rm -r "$tablename"
        echo "Table '$tablename' dropped successfully."
    else
        echo "Table '$tablename' does not exist."
    fi
}

function insertIntoTable {
    listTables
    read -p "Enter table name: " tablename
    if [ ! -d "$tablename" ]; then
        echo "Table '$tablename' does not exist."
        return
    fi

    metadata=$(cat "$tablename/metadata")
    columns=$(echo "$metadata" | sed 's/,primary:.*//')

    primaryKeyCol=$(echo "$metadata" | grep -o 'primary:[^,]*' | cut -d':' -f2)

    IFS=',' read -r -a colArray <<< "$columns"

    row=""
    colNames=()
    colTypes=()

    for col in "${colArray[@]}"; do
        IFS=':' read -r -a colDetails <<< "$col"
        colNames+=("${colDetails[0]}")
        colTypes+=("${colDetails[1]}")
    done

    while true; do
        read -p "Enter values for columns (${colNames[*]}), separated by commas: " inputValues
        IFS=',' read -r -a values <<< "$inputValues"

        if [ ${#values[@]} -ne ${#colNames[@]} ]; then
            echo "Error: You must enter a value for each column."
            continue
        fi

        valid=true
        for i in "${!values[@]}"; do
            value="${values[$i]}"
            colName="${colNames[$i]}"
            colType="${colTypes[$i]}"

            if [[ "$colType" == "int" && ! "$value" =~ ^[0-9]+$ ]]; then
                echo "Invalid input for $colName. Expected integer."
                valid=false
                break
            fi

            if [[ "$colName" == "$primaryKeyCol" && "$(grep -c "^$value$DELIMITER" "$tablename/data")" -gt 0 ]]; then
                echo "Primary key '$value' already exists. Please enter a unique value."
                valid=false
                break
            fi
        done

        if [ "$valid" == true ]; then
            break
        fi
    done

    row=$(IFS=','; echo "${values[*]}")
    echo "$row" >> "$tablename/data"
    echo "Row inserted successfully."
}


function selectFromTable {
    listTables
    read -p "Enter table name: " tablename
    if [ ! -d "$tablename" ]; then
        echo "Table '$tablename' does not exist."
        return
    fi

    metadata=$(cat "$tablename/metadata")
    columns=$(echo "$metadata" | cut -d',' -f1)

    echo "Table: $tablename"
    echo "$columns" | column -t -s ','
    echo "-----------------------------"
    column -t -s "$DELIMITER" "$tablename/data"
}


function deleteFromTable {
    listTables
    read -p "Enter table name: " tablename
    if [ ! -d "$tablename" ]; then
        echo "Table '$tablename' does not exist."
        return
    fi

    read -p "Enter condition column name: " colName
    read -p "Enter condition value: " colValue

    metadata=$(cat "$tablename/metadata")
    columns=$(echo "$metadata" | cut -d',' -f1)
    IFS=',' read -r -a colArray <<< "$columns"

    colIndex=-1
    for i in "${!colArray[@]}"; do
        colField=$(echo "${colArray[$i]}" | cut -d':' -f1) 
        if [[ "$colField" == "$colName" ]]; then
            colIndex=$((i+1))  
            break
        fi
    done

    if [ "$colIndex" -eq -1 ]; then
        echo "Column '$colName' not found."
        return
    fi

    awk -v colIndex="$colIndex" -v colValue="$colValue" -v delimiter="$DELIMITER" '
    BEGIN { FS=delimiter; OFS=delimiter }
    { if ($colIndex != colValue) print }
    ' "$tablename/data" > temp && mv temp "$tablename/data"

    echo "Row(s) deleted successfully."
}


function updateTable {
    listTables
    read -p "Enter table name: " tablename
    if [ ! -d "$tablename" ]; then
        echo "Table '$tablename' does not exist."
        return
    fi

    metadata=$(cat "$tablename/metadata")
    columns=$(echo "$metadata" | sed 's/,primary:.*//')  

    IFS=',' read -r -a colArray <<< "$columns"

    echo "Available columns: ${colArray[*]}"

    read -p "Enter condition column name: " colName
    read -p "Enter condition value: " colValue
    read -p "Enter column name to update: " updateCol
    read -p "Enter new value: " newValue

    colIndex=-1
    updateIndex=-1
    for i in "${!colArray[@]}"; do
        colField=$(echo "${colArray[$i]}" | cut -d':' -f1)
        if [[ "$colField" == "$colName" ]]; then
            colIndex=$((i+1))          fi
        if [[ "$colField" == "$updateCol" ]]; then
            updateIndex=$((i+1))
        fi
    done

    if [[ "$colIndex" -eq -1 ]]; then
        echo "Error: Column '$colName' not found."
        return
    fi
    if [[ "$updateIndex" -eq -1 ]]; then
        echo "Error: Column '$updateCol' not found."
        return
    fi

    delimiter=","
    firstLine=$(head -n 1 "$tablename/data")
    if [[ "$firstLine" == ";" ]]; then
        delimiter=";"
    fi

    awk -v colIndex="$colIndex" -v colValue="$colValue" -v updateIndex="$updateIndex" -v newValue="$newValue" -v FS="$delimiter" -v OFS="$delimiter" '
    BEGIN { updated=0 }
    {
        if ($colIndex == colValue) { 
            $updateIndex = newValue
            updated=1
        }
        print
    }
    END { if (updated==0) print "Warning: No matching rows found." > "/dev/stderr" }
    ' "$tablename/data" > temp && mv temp "$tablename/data"

    echo "Row(s) updated successfully."
}

if [ -d "Database" ]; then
    cd Database
    mainMenu
else
    mkdir Database
    cd Database
    mainMenu
fi





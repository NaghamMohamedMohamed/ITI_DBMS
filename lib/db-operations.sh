#!/bin/bash


source ./lib/table-menu.sh

DB_PATH="./Databases"


# Function to create a new database
create_db() 
{
    #check if the main database directory exists, if not, it is created
    if [[ ! -d $DB_PATH ]]; then
        mkdir -p "$DB_PATH"
    fi

    while true; do
        echo -e "Enter the name of the database or press 'q' to quit:"
        read dbname

        # Check if user wants to quit
        if [[ $dbname == "q" ]]; then
            echo "Exiting database creation..."
            break
        fi

        # Check if the database already exists
        if [[ -d "$DB_PATH/$dbname" ]]; then
            echo "Database '$dbname' already exists!"
        else
            mkdir "$DB_PATH/$dbname"
            echo "Database '$dbname' was created successfully!"
        fi
    done
}


# Function to list all databases
list_db() 
{
    # Checking if the databases directory exists
    if [[ ! -d $DB_PATH ]]; then
        echo "Error: Database directory '$DB_PATH' not found!"
        return 1
    fi

    # Listing only directories
    databases=$(find "$DB_PATH" -mindepth 1 -maxdepth 1 -type d | sed "s|$DB_PATH/||")
    # mindepth 1 : so it doesnt display the parent directory
    # maxdepth 1 : so it doesnt display the subdirectories only child directories
    # type d : only directories not files
    # sed : to replace the path from the output with empty string
    if [[ -z "$databases" ]]; then
        echo "No Databases Found!"
    else
        echo "List of Databases :"
        echo "- $databases"
    fi
}


# Function to connect to a database (calls table operations menu)
connect_to_db ()
{
    read -p "Enter the database name to connect : " db_name
    if [[ -d "$DB_PATH/$db_name" ]]; then
        echo
        echo "Connected to database : $db_name"
        export db_name

        sleep 1
        clear
        sub_menu

    else
        echo
        echo "Database does not exist!"
    fi
}


# Function to drop/delete a database
drop_db ()
{
    read -p "Enter database name to delete : " db_name
    if [[ -d "$DB_PATH/$db_name" ]]; then
        rm -r "$DB_PATH/$db_name"
        echo
        echo "Database '$db_name' was deleted successfully."
    else
        echo
        echo "Database does not exist!"
    fi
}


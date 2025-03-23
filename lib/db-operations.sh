#!/bin/bash
source ./validations.sh
create_db() {
    DB_PATH="./Databases"

    #check if the main database directory exists, if not, it is created
    if [[ ! -d $DB_PATH ]]; then
        mkdir -p "$DB_PATH"
    fi

    while true; do
        echo -e "Enter the name of the database or press 'q' to quit:"
        read dbname

        #check if user wants to quit
        if [[ $dbname == "q" ]]; then
            echo "Exiting database creation..."
            break
        fi

        #check if the database already exists
        if [[ -d "$DB_PATH/$dbname" ]]; then
            echo "Database '$dbname' already exists!"
        else
            mkdir "$DB_PATH/$dbname"
            echo "Database '$dbname' created successfully!"
        fi
    done
}

list_db() {

    DB_PATH="./Databases"
    #checking if the databases directory exists
    if [[ ! -d $DB_PATH ]]; then
        echo "Error: Database directory '$DB_PATH' not found!"
        return 1
    fi

    #listing only directories
    databases=$(find "$DB_PATH" -mindepth 1 -maxdepth 1 -type d | sed "s|$DB_PATH/||")
    #mindepth 1 : so it doesnt display the parent directory
    #maxdepth 1 : so it doesnt display the subdirectories only child directories
    #type d : only directories not files
    #sed : to replace the path from the output with empty string
    if [[ -z "$databases" ]]; then
        echo "No Databases Found!"
    else
        echo "List of Databases:"
        echo "$databases"
    fi
}
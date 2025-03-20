# This file is for tables CRUD Operations : Create , List , Update , Drop
#!/bin/bash
source ./validations.sh

#-----------Creating a new table------------------
create_table(){
    while true; do
        echo -e "Enter the name of the table or press 'q' to quit:"
        read tablename

        #check if user wants to quit
        if [[ $tablename == "q" ]]; then
            echo "Exiting table creation..."
            break
        fi

##########
#to be added: validate table name (no spaces, only letters, numbers, and underscores)
##########

        #check if the table name is empty
        if [[ -z "$tablename" ]]; then
            echo "Table name cannot be empty!"
            continue
        fi

        #check if the table already exists
        if [[ -f "$DB_PATH/$DB_NAME/$tablename" ]]; then
            echo "Table '$tablename' already exists!"
        else
            touch "$DB_PATH/$DB_NAME/$tablename"
            echo "Table '$tablename' created successfully!"
        fi
    done

}
#---------List all existing tables--------------------
list_tables(){
    if [[ $(ls -p "$DB_PATH/$DB_NAME" | grep -v / | wc -l) -eq 0 ]]; then
        echo "No Tables Found!"
    fi

    else
        echo "List of Tables:"
        ls -p $DB_PATH/$DB_NAME | grep -v /
    fi
}

#-----------Update a table------------------
update_table(){

}

#-----------Drop a table------------------

drop_table() {
    while true; do
        #list all tables in the current database (excluding directories)
        tables=($(ls -p $DB_PATH/$DB_NAME | grep -v /))

        #if no tables exist, inform the user and exit
        if [[ ${#tables[@]} -eq 0 ]]; then
            echo "No tables found in the database!"
            break
        fi

        #display available tables with numbering
        echo "Tables in the database:"
        for i in "${!tables[@]}"; do
            echo "$(($i + 1)). ${tables[$i]}"
        done

        #ask the user to select a table by number or quit
        echo -e "Enter the number of the table to drop or 'q' to quit:"
        read choice

        #check if the user wants to exit
        if [[ $choice == "q" ]]; then
            echo "Exiting table deletion..."
            break
        fi

###################
        #to be added: validate if the choice is a valid number within the table list range
###################

        #confirm the user wants to delete the table
        read -p "Are you sure you want to delete '$tablename'? (y/n): " confirm
        if [[ $confirm != [Yy] ]]; then
            echo "Table deletion canceled."
            continue
        fi

        #create a trash directory to store deleted tables for recovery
        TRASH_DIR="$DB_PATH/$DB_NAME/trash"
        mkdir -p "$TRASH_DIR"  

        #move the selected table to the trash folder instead of permanently deleting it
        mv "$DB_PATH/$DB_NAME/$tablename" "$TRASH_DIR/"
        echo "Table '$tablename' moved to trash. Use 'restore_table' to recover it."

        #log the deletion event with timestamp and user information
        LOG_FILE="$DB_PATH/$DB_NAME/deletion.log"
        echo "$(date) - Table '$tablename' deleted by user $USER" >> "$LOG_FILE"
    done
}


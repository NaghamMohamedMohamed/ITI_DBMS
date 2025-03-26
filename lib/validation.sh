#!/bin/bash


DB_PATH="./Databases"

# Function to validate DB/Table name before creation
validate_name() 
{
    # A local variable to store the db/table name passed as an argument to this fucntion
    local name="$1"

    # Replace the space in the DB/Table name with underscore ( _ )
    name="${name// /_}"

    # Validate database/table name
    if [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        echo
        echo "Invalid name. It must start with a letter and contain only letters, numbers, and underscores."
        echo
        return 2
    fi

}


# Function to validate DB existence before creation
db_isExist()
{
    # Convert db/table name to lowercase
    local dbname_lower=$(echo "$dbname" | tr '[:upper:]' '[:lower:]')

    #loops through the existing dBs and convert each dB name to lowercase to compare with the entered name
    for existing_db in "$DB_PATH"/*; do
        existing_db_name=$(basename "$existing_db" | tr '[:upper:]' '[:lower:]')
        if [[ "$existing_db_name" == "$dbname_lower" ]]; then
            # The dB exists
            return 0  
        fi
    done
   
    return 1
}


# Function to validate Table existence before creation
table_isExist()
{
    # Convert db/table name to lowercase
    local tablename_lower=$(echo "$tablename" | tr '[:upper:]' '[:lower:]')

    # Loops through the existing tabless and convert each dB name to lowercase to compare with the entered name
    for existing_table in "$DB_PATH"/$DB_NAME*; do
        existing_table_name=$(basename "$existing_table" | tr '[:upper:]' '[:lower:]')
        if [[ "$existing_table_name" == "$tablename_lower" ]]; then
            # The table exists
            return 0  
        fi
    done
   
    return 1
}


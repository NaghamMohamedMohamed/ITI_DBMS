#!/bin/bash


# Function to validate DB before creation , connection , dropping.
validate_db() 
{
    # A local variable to store the db name passed as an argument to this fucntion
    local dbname="$1"

    # Validate database name
    if [[ ! "$dbname" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        echo
        echo "Invalid database name. It must start with a letter and contain only letters, numbers, and underscores."
        echo
        return 2
    fi
    
    # Convert db name to lowercase
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


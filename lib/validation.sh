# This file is for data validation ( data types , primary key )
#!/bin/bash

# Function to check if a database exists (case-insensitive)
database_exists() {
    local dbname="$1"
    #convert the entered dB name to lowercase
    local dbname_lower=$(echo "$dbname" | tr '[:upper:]' '[:lower:]')

    #loops through the existing dBs and convert each dB name to lowercase to compare with the entered name
    for existing_db in "$DB_PATH"/*; do
        existing_db_name=$(basename "$existing_db" | tr '[:upper:]' '[:lower:]')
        if [[ "$existing_db_name" == "$dbname_lower" ]]; then
            return 0  # the dB exists
        fi
    done

    return 1  # dB does not exist
}

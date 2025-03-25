#!/bin/bash


# Function to validate DB before creation , connection , dropping.
validate_db() 
{
    # A local variable to store the db name passedas an argument to this fucntion
    local dbname="$1"

    # Validate database name
    if [[ ! "$dbname" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        echo "Invalid database name. It must start with a letter and contain only letters, numbers, and underscores."
        echo
        return 0
    fi

    
    # Convert db name to lowercase
    local dbname_lower=$(echo "$dbname" | tr '[:upper:]' '[:lower:]')

    # Validate database pre-existence 
    if [[ -d "$DB_PATH/$dbname_lower" ]]; then
        # DB exists
        echo "Database '$dbname' already exists!"
        echo
        return 0
    fi

    return 1
}


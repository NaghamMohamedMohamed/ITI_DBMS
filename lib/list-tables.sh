#!/bin/bash
source ./lib/validation.sh
DB_PATH="./Databases"

#---------List all existing tables--------------------
list_tables() {
    # Store the list of tables in an array
    local tables=($(ls | grep -Ev "/|@meta$")) # lists only files (tables)

    # Check if tables exist
    if [[ ${#tables[@]} -eq 0 ]]; then
        echo "No Tables Found!"
    else
        echo "List of Tables:"
        echo "==============="
        for i in "${!tables[@]}"; do
            echo "$((i + 1))) ${tables[$i]}" # Display tables with numbering
        done
    fi
}
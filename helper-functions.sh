#!/bin/bash


# Function to get table name and extract its meta data ( through read_table_metadata function )
get_table() 
{
    while true; do
        # List all tables (excluding metadata files)
        table_list=($(ls | grep -Ev "/|@meta$"))

        # If no tables exist, inform the user and exit
        if [[ ${#table_list[@]} -eq 0 ]]; then
            echo "No tables found in the '$DB_NAME' database!"
            return 1  # Return an error status
        fi 

        echo "Tables List in '$DB_NAME' database "
        echo "===================================="

        for i in "${!table_list[@]}"; do
            echo "$((i+1)). ${table_list[i]}"
        done
        echo "===================================="
        echo

        read -p "Enter the number of the table to insert/select/delete into/from ( or press 'q' to exit ) : " choice

        # Exit if user presses 'q' or 'Q'
        if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
            echo "Operation is canceled."
            return 1
        fi

        # Validate input (must be a number within range)
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#table_list[@]} )); then
            # Set the chosen table as active
            tablename="${table_list[choice-1]}"
            # Load table metadata
            read_table_metadata "$tablename"
            # Successful operation
            return 0  
        else
            echo
            echo "Invalid choice! Please enter a valid number or 'q' to exit."
            echo
        fi
    done
}


# Function to read the primary key column , data types , number and names of the columns in a table from the @meta file
read_table_metadata() 
{
    tablename="$1"  # Set the table name from function argument
    IFS=':' read -r -a columns < <(head -1 "$tablename@meta")
    num_columns=${#columns[@]}    
    data_types=($(get_data_types "$tablename" | tr ':' ' '))
    primary_key=$(sed -n '3p' "$tablename@meta" | awk -F':' '{print $2}')
    # Trim spaces from primary key
    primary_key=$(echo "$primary_key" | xargs)

}


#!/bin/bash

source ./helper-functions.sh
source ./lib/validation.sh

# A function to display table insertion options
insert_into_table()
{
    # If table selection fails, exit
    get_table || return  

    while true; do
        echo
        echo "==========================="
        echo "  Insert into Table Menu "
        echo "==========================="
        echo "1) Insert a new row."
        echo "2) Insert a new column."
        echo "3) Insert a new value in an empty cell."
        echo "4) Exit."
        echo
        read -p "Enter your choice : " choice
        echo

        case $choice in
            1) insert_new_row "$tablename" ;;
            2) insert_new_column "$tablename" ;;
            3) insert_in_empty_cell "$tablename" ;;
            4) echo "Returning to the previous sub-menu...";  
                sleep 1
                clear
                return ;;
            *) echo
                echo "❌ Invalid choice. Please try again." 
                echo ;;
        esac
    done
            
}


# Function to insert a new row into the table
insert_new_row() 
{
    local tablename=$1
    # Load table metadata  
    read_table_metadata "$tablename"

    # Initialize an array to store the new row values
    local new_row=()

    # Loop through each column to get user input
    for ((i = 0; i < num_columns; i++)); do
        local col_name="${columns[i]}"
        local col_type="${data_types[i]}"

        # Trim spaces from column name and primary key
        col_name=$(echo "$col_name" | xargs)

        while true; do
            read -p "Enter value for $col_name ( $col_type ) ( Press Enter to set NULL ) : " new_value
            echo

            # If the column is the primary key, ensure it's not NULL or spaces
            if [[ "$col_name" == "$primary_key" ]]; then
                if [[ -z "$new_value" || "$new_value" =~ ^[[:space:]]+$ ]]; then
                    echo "❌ Error: Primary key '$primary_key' cannot be empty or NULL! Please enter a valid value."
                    echo
                    # Ask for input again
                    continue  
                fi
                
                # Check if the primary key value already exists
                if grep -q "^$new_value:" "$tablename"; then
                    echo "⚠️ A row with primary key value '$new_value' already exists! Please enter a unique value."
                    echo
                    continue
                fi
            fi
            
            # If input is empty or just spaces, set it to NULL
            if [[ -z "$new_value" || "$new_value" =~ ^[[:space:]]+$ ]]; then
                new_value="NULL"
            fi

            validate_data_type "$((i+1))" "$new_value"
            if [[ $? -eq 0 ]]; then
                new_row+=("$new_value")  
                break
            else
                continue
            fi
        done
    done

    # Append the new row to the table file
    echo "${new_row[*]}" | tr ' ' ':' >> "$tablename"
    echo
    echo "✅ Row is inserted successfully into '$tablename'!"
}



# Function to insert a new column into the table 
insert_new_column() 
{
    local tablename=$1

    # Load table metadata
    read_table_metadata "$tablename"

    # Ask user for the new column name
    while true; do
        read -p "Enter the new column name : " new_col_name
        validate_name "$new_col_name"
        case $? in
            0) 
                echo
                echo "❌ Invalid column name. Must start with a letter and contain only letters, numbers, and underscores."
                echo
                return ;;
        esac

        for ((i = 0; i < num_columns; i++)); do
            if [[ "${columns[i]}" == "$new_col_name" ]]; then
                echo
                echo "⚠️ Column '$new_col_name' already exists!"
                echo
                return
            fi
        done
        break
    done
    echo
    # Ask user for the new column data type
    while true; do
        echo "Choose data type for '$new_col_name': "
        echo "1. Int"
        echo "2. String"
        echo
        read -p "Enter choice (1 or 2) : " col_type

        case $col_type in
            1) new_col_type="Int"; break ;;
            2) new_col_type="String"; break ;;
            *) echo "❌ Invalid choice. Please enter 1 or 2." ;;
        esac
    done

    # Update meta file
    sed -i "1s/$/:$new_col_name/" "$tablename@meta"
    sed -i "2s/$/:$new_col_type/" "$tablename@meta"


    # Append `NULL` to each row in the table file
    sed -i "s/$/:NULL/" "$tablename"
    echo
    echo "✅ Column '$new_col_name' is added successfully with default 'NULL' values!"
}


# Function to insert a new value in an empty cell
insert_in_empty_cell() 
{
    local tablename=$1

    # Load table metadata
    read_table_metadata "$tablename"


    # Find the index of the primary key column
    local primary_key_index=-1
    for ((i=0; i<num_columns; i++)); do
        if [[ "${columns[i]}" == "$primary_key" ]]; then
            primary_key_index=$i
            break
        fi
    done


    if [[ $primary_key_index -eq -1 ]]; then
        echo "⚠️  Primary key column '$primary_key' not found in metadata!"
        return 1
    fi

    
    # Ask user for the primary key value
    read -p "Enter the value of the row primary key ($primary_key) to insert into : " primary_key_value
    echo

    # Find the row number that matches the primary key value
    local row_num=$(awk -F: -v key="$primary_key_value" -v col="$((primary_key_index + 1))" '$col == key {print NR}' "$tablename")

    # Validate if row exists
    if [[ -z "$row_num" ]]; then
        echo "⚠️ No row found with primary key value '$primary_key_value'!"
        return 1
    fi

    echo
    # Ask user for the column name to update
    echo "Available columns : $(echo "${columns[*]}" | sed 's/ / | /g')"

    echo
    read -p "Enter the column to insert into : " target_col
    echo

    # Get column index
    local col_index=-1
    for ((i=0; i<num_columns; i++)); do
        if [[ "${columns[i]}" == "$target_col" ]]; then
            col_index=$i
            break
        fi
    done

    if [[ $col_index -eq -1 ]]; then
        echo "⚠️ Column '$target_col' not found!"
        return 1
    fi

    # Get the current value in the target cell
    local current_value=$(awk -F: -v row="$row_num" -v col="$((col_index+1))" 'NR == row {print $col}' "$tablename")

    # Ensure the cell is empty before inserting
    if [[ "$current_value" != "NULL" ]]; then
        echo
        echo "❌ This cell already has a value!"
        return 1
    fi
    echo
    # Ask for new value
    read -p "Enter the new value for column '$target_col' : " new_value

    # Validate data type (ensure it matches the one in the metadata)
    if ! validate_data_type "$((col_index+1))" "$new_value"; then
        echo "❌ Invalid data type for column '$target_col'!"
        return 1
    fi


    awk -F: -v row="$row_num" -v col="$((col_index+1))" -v new_val="$new_value" '
    BEGIN { OFS=":" }
    NR == row { $col = new_val }
    { print }
    ' "$tablename" > temp && mv temp "$tablename"

    echo
    echo "✅ Value is inserted successfully into column '$target_col' (Row with $primary_key = $primary_key_value)!"
}
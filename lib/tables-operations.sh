#!/bin/bash
source ./lib/validation.sh
DB_PATH="./Databases"

# Function to create a new table
create_table() {
    while true; do
        read -p "Enter the name of the table or press 'q' to quit: " tablename

        # Check if user wants to quit
        if [[ $tablename == "q" || $tablename == "Q" ]]; then
            echo "Exiting table creation operation..."
            echo
            return
        fi

        # Check if the table name is empty
        if [[ -z "$tablename" ]]; then
            echo "Table name cannot be empty!"
            echo
            continue
        fi

        validate_name "$tablename"
        case $? in
            0) 
                echo
                echo "Invalid table name. It must start with a letter and contain only letters, numbers, and underscores."
                echo
                return ;;
        esac

        table_isExist "$tablename"
        case $? in
            0)  
                echo
                echo "Table '$tablename' already exists!"
                echo
                return ;;  # If table exists, exit function
        esac

        # If we reach here, the table name is valid and does not exist -> break loop
        break
    done

    # Loop until user enters a valid number of columns
    while true; do
        read -p "Enter the number of columns: " num_columns
        if [[ "$num_columns" =~ ^[1-9][0-9]*$ ]]; then
            break  # Valid input, exit loop
        else
            echo "Invalid number of columns. Please enter a positive integer."
        fi
    done

    # Store column metadata
    columns=()
    types=()

    for ((i=1; i<=num_columns; i++)); do
        read -p "Enter name of column $i: " col_name
        validate_name "$col_name"
        case $? in
            0) 
                echo
                echo "Invalid column name. It must start with a letter and contain only letters, numbers, and underscores."
                return ;;
        esac

        col_isExist "$col_name"
        case $? in
            0)  
                echo
                echo "Column '$col_name' already exists!"
                echo ;;    
        esac

        # Choose data type with validation
        while true; do
            echo "Choose data type for '$col_name':"
            echo "1. int"
            echo "2. string"
            echo
            read -p "Enter choice (1 or 2): " col_type
            echo

            if [[ "$col_type" == "1" ]]; then
                col_type="int"
                break
            elif [[ "$col_type" == "2" ]]; then
                col_type="string"
                break
            else
                echo "Invalid choice. Please enter 1 or 2."
                echo
            fi
        done

        # Store column metadata
        columns+=("$col_name")
        types+=("$col_type")
    done

    # Ask user to select the primary key column
    echo
    echo "Select the primary key column:"
    select primary_key in "${columns[@]}"; do
        if [[ -n "$primary_key" ]]; then
            break
        else
            echo "Invalid selection. Please choose a valid column."
        fi
    done

    touch "$tablename"
    # Store column names and types in the table file
    {
        echo "${columns[*]}"
        echo "${types[*]}"
        echo "PrimaryKey: $primary_key"
    } > "$tablename"

    echo
    echo "Table '$tablename' created successfully with primary key '$primary_key'!"
}


#---------List all existing tables--------------------
list_tables() {
    # Store the list of tables in an array
    local tables=($(ls | grep -v /)) # lists only files (tables)

    # Check if tables exist
    if [[ ${#tables[@]} -eq 0 ]]; then
        echo "No Tables Found!"
    else
        echo "List of Tables:"
        for i in "${!tables[@]}"; do
            echo "$((i + 1)). ${tables[$i]}" # Display tables with numbering
        done
    fi
}

#-----------Update a table------------------

#-----------Drop a table------------------
drop_table() {
    while true; do
        # List all tables (excluding metadata files)
        tables=($(ls | grep -Ev "/|@meta$"))

        # If no tables exist, inform the user and exit
        if [[ ${#tables[@]} -eq 0 ]]; then
            echo "No tables found in the database!"
            return
        fi
        echo
        # Display available tables with numbering
        echo "Tables in the '$DB_NAME' database:"
        for i in "${!tables[@]}"; do
            echo "$(($i + 1)). ${tables[$i]}"
        done

        # Ask the user to select a table by number or quit
        echo
        read -p "Enter the number of the table to drop (or press 'q' to exit):" choice        

        # Check if the user wants to exit
        if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
            echo "Exiting table deletion..."
            return
        fi

        # Validate if choice is a number within range
        if ! [[ "$choice" =~ ^[0-9]+$ ]] || ((choice < 1 || choice > ${#tables[@]})); then
            echo
            echo "Invalid input. Please enter a valid table number."
            echo
            continue
        fi

        # Get the selected table name
        tablename="${tables[$((choice - 1))]}"

        # Confirm deletion
        read -p "Are you sure you want to delete '$tablename'? (y/n): " confirm
        echo
        if [[ "$confirm" != [Yy] ]]; then
            echo "Table deletion canceled."
            return
        fi
        rm $tablename
        echo "Table $tablename is deleted successfully!"

    done
}

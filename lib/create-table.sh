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

        # Validate table name
        validate_name "$tablename"
        if [[ $? -eq 0 ]]; then
            echo
            echo "Invalid table name. It must start with a letter and contain only letters, numbers, and underscores."
            echo
            continue
        fi

        # Check if the table already exists
        table_isExist "$tablename"
        if [[ $? -eq 0 ]]; then
            echo
            echo "Table '$tablename' already exists!"
            echo
            return
        fi 

        # Create table files
        touch "$tablename"
        touch "$tablename@meta"
        break
    done

    while true; do
        read -p "Enter the number of columns: " num_columns
        if [[ "$num_columns" =~ ^[1-9][0-9]*$ ]]; then
            break  # Valid input, exit loop
        else
            echo "Please enter a valid number of columns."
        fi
    done

    # Store column metadata 
    column_names=()
    data_types=()
    for ((i=1; i <= num_columns; i++)); do
        while true; do
            flag=0
            read -p "Enter the name of column $i: " col_name
            echo
            col_name=$(echo "$col_name" | tr ' ' '_')  # Replace spaces with underscores

            # Validate column name
            validate_name "$col_name"
            if [[ $? -eq 0 ]]; then
                echo "Invalid column name. It must start with a letter and contain only letters, numbers, and underscores."
                continue
            fi

            # Check if the column already exists
            col_isExist "$col_name"
            if [[ $? -eq 0 ]]; then
                echo "Column '$col_name' already exists!"
                continue
            fi

            column_names+=("$col_name")
            break
        done

        # Choose data type
        while true; do
            echo "Choose the type of column $col_name: "
            select input in "Int" "String"; do
                case $REPLY in
                    1)
                        data_types+=("Int")
                        break 2
                        ;;
                    2)
                        data_types+=("String")
                        break 2
                        ;;
                    *)
                        echo "Invalid input. Please choose 1 or 2."
                        ;;
                esac
            done
        done
    done

    # Ask user to select the primary key column
    echo
    echo "Select the primary key column:"
    select primary_key in "${column_names[@]}"; do
        if [[ -n "$primary_key" ]]; then
            break
        else
            echo "Invalid selection. Please choose a valid column."
        fi
    done

    # Store metadata
    name=""
    type=""
    for ((i=0; i<${#column_names[@]}; i++)); do
        # Append column names and data types to a single string
        name+="${column_names[i]}:"
        type+="${data_types[i]}:"
    done

    # Write metadata to the table file
    echo "${name::-1}" >> "$tablename@meta"
    echo "${type::-1}" >> "$tablename@meta"
    echo "PrimaryKey: $primary_key" >> "$tablename@meta"
    echo "Table $tablename created successfully!"
    echo
    sleep 3
}
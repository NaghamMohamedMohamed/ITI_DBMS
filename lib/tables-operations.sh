#!/bin/bash
source ./lib/validation.sh
#source ./lib/table-menu.sh
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
update_table() {

        #  List tables with numbers
        table_list=($(ls )) # Store tables in an array
        
        echo "=========Tables List in '$DB_NAME'============="
        for i in "${!table_list[@]}"; do
            echo "$((i+1)). ${table_list[i]}"
        done

        echo
        read -p "Enter the number of the table to update to (or press 'q' to exit): " choice

        # Exit if user presses 'q' or 'Q'
        if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
            echo "Operation is canceled."
            return 0
        fi

        # Validate input (must be a number within range)
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#table_list[@]} )); then
            table="${table_list[choice-1]}" # Set the chosen table as active

            while true; do
                echo "========================"
                echo "  Update Table Menu"
                echo "========================"
                echo "1) Update by Row"
                echo "2) Update by Column"
                echo "3) Update a Single Value (Cell)"
                echo "4) Exit"
                echo
                read -p "Enter your choice: " choice

                case $choice in
                    1) update_by_row "$tablename" ;;
                    2) update_by_column "$tablename" ;;
                    3) update_record "$tablename" ;;
                    4) echo "Returning to the previous sub-menu...";  
                        sleep 1
                        clear
                        #sub_menu 
                        return
                        ;;
                    *) echo "Invalid choice. Please try again." ;;
                esac
            done
            
        else
            echo
            echo "Invalid choice! Please enter a valid number or 'q' to exit."
            return
        fi
}

# Function to update a row by primary key
update_by_row() {

    # Assign the table name from the argument
    local table="$1"
    echo $table

    read -p "Enter the primary key of the record to update: " primary_key

    pk=$(awk -F": " '/primary key/ {print $2}' $tablename)
    echo "$pk"

    # Find the row with the primary key
    # used awk to find the row where the primary key matches the user input
    # -v key="$primary_key" is used to pass the primary key value to awk
    # $1 is the first column which is the primary key
    # $0 is the whole line
    row=$(awk -F, -v key="$primary_key" '$1 == key {print NR, $0}' "$DB_PATH/$DB_NAME/$table")
    

    # Check if the row exists
    if [[ -z "$row" ]]; then
        echo "Error: No record found with primary key '$primary_key'."
        return 1
    fi

    # Extract the row number and the existing record
    row_number=$(echo "$row" | cut -d ' ' -f1)
    existing_record=$(echo "$row" | cut -d ' ' -f2-)

    echo "Existing Record: $existing_record"

    # Get column names
    # Read the first line of the table file and store the column names in an array
    IFS=',' read -r -a columns < "$DB_PATH/$DB_NAME/$table"

    # Store the primary key and existing values in an array
    new_values=("$primary_key") # Keep the primary key unchanged

    # Loop through the columns and ask the user to enter new values
    for ((i=1; i<${#columns[@]}; i++)); do
        echo "Enter new value for column ${columns[$i]}:"
        read new_value
        new_values+=("$new_value")
    done

    # Join the new values into a single string with a comma separator
    updated_row=$(IFS=,; echo "${new_values[*]}")

    # used sed to replace the existing row with the updated row
    sed -i "${row_number}s/.*/$updated_row/" "$DB_PATH/$DB_NAME/$table"

    echo "Row updated successfully!"
}

# Function to update each cell in a column individually
update_by_column() {
    local table="$1"

    read -p "Enter the column name to update: " column_name

    # Get column index
    # used awk to find the index of the column name in the first row
    # passes the column name to awk using -v col="$column_name"
    # NR==1 is used to match the first row (header row)
    # for loop is used to iterate over each field in the first row
    # if the field matches the column name, the index is printed
    col_index=$(awk -F, -v col="$column_name" 'NR==1 {for (i=1; i<=NF; i++) if ($i == col) print i}' "$DB_PATH/$DB_NAME/$table")

    if [[ -z "$col_index" ]]; then
        echo "Error: Column '$column_name' not found."
        return 1
    fi

    echo "Updating column '$column_name' row by row:"

    # Read the table line by line (excluding the header)
    # IFS=, is used to split each line by comma
    # read -r -a row is used to store the fields in an array
    # while loop is used to iterate over each row
    # the primary key is stored in the first field
    # the current value of the column is stored in the field with the column index
    # the user is asked to enter a new value
    # if the user enters a value, the field is updated
    # the updated row is joined into a single string with a comma separator
    # sed is used to replace the existing row with the updated row
    while IFS=, read -r -a row; do
        primary_key="${row[0]}"
        current_value="${row[$((col_index - 1))]}"

        echo "Current value for $primary_key ($column_name): $current_value"
        read -p "Enter new value (or press Enter to keep the same): " new_value

        # Only update if the user entered something
        if [[ -n "$new_value" ]]; then
            row[$((col_index - 1))]="$new_value"
        fi

        # Join the updated row into a single string
        updated_row=$(IFS=,; echo "${row[*]}")
        sed -i "/^$primary_key,/c\\$updated_row" "$DB_PATH/$DB_NAME/$table"
    done < <(tail -n +2 "$DB_PATH/$DB_NAME/$table") # Skip the header line

    echo "Column '$column_name' updated successfully!"
    echo
}

# Function to update a single record
update_record() {
    local table="$1"

    read -p "Enter the primary key of the record to update: " primary_key

    # Find the row with the primary key
    row=$(awk -F, -v key="$primary_key" '$1 == key {print NR, $0}' "$DB_PATH/$DB_NAME/$table")

    if [[ -z "$row" ]]; then
        echo "Error: No record found with primary key '$primary_key'."
        return 1
    fi

    row_number=$(echo "$row" | cut -d ' ' -f1)

    echo "Enter the column name to update:"
    read column_name

    # Get column index
    col_index=$(awk -F, -v col="$column_name" 'NR==1 {for (i=1; i<=NF; i++) if ($i == col) print i}' "$DB_PATH/$DB_NAME/$table")

    if [[ -z "$col_index" ]]; then
        echo "Error: Column '$column_name' not found."
        return 1
    fi

    read -p "Enter the new value for '$column_name': " new_value

    # Replace the specific field
    # used awk to update the field in the specified row and column
    # -v row="$row_number" is used to pass the row number to awk
    # -v col="$col_index" is used to pass the column index to awk
    # -v val="$new_value" is used to pass the new value to awk
    # BEGIN{FS=OFS=","} is used to set the field separator to comma
    # NR==row is used to match the row number
    # $col=val is used to update the field at the specified column
    # 1 is used to print the updated row
    awk -v row="$row_number" -v col="$col_index" -v val="$new_value" 'BEGIN{FS=OFS=","} NR==row{$col=val}1' "$DB_PATH/$DB_NAME/$table" > temp_file && mv temp_file "$DB_PATH/$db_name/$table"

    echo "Record updated successfully!"
    echo
}


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

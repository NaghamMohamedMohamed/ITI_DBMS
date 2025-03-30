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

#-----------Update a table------------------
update_table(){
        # List tables with numbers
        # Excludes directories and metadata files
        table_list=($(ls | grep -Ev "/|@meta$")) # Store tables in an array
        
        echo "=============== Tables List in '$DB_NAME' Database ==============="
        for i in "${!table_list[@]}"; do
            echo "$((i+1)). ${table_list[i]}"
        done

        echo
        read -p "Enter the number of the table to update (or press 'q' to exit): " choice
        echo

        # Exit if user presses 'q' or 'Q'
        if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
            echo "Operation is canceled."
            return 0
        fi

        # Validate input (must be a number within range)
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#table_list[@]} )); then
            tablename="${table_list[choice-1]}" # Set the chosen table as active

            while true; do
                echo "========================"
                echo " Update Table Menu "
                echo "========================"
                echo "1) Update by Row"
                echo "2) Update by Column"
                echo "3) Update a Single Value (Cell)"
                echo "4) Exit"
                echo
                read -p "Enter your choice: " choice
                echo

                case $choice in
                    1) update_by_row "$tablename" ;;
                    2) update_by_column "$tablename" ;;
                    3) update_cell "$tablename" ;;
                    4) echo "Returning to the previous sub-menu...";  
                        sleep 1
                        clear
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


update_by_row() {
    local tablename=$1

    # Read metadata
    local columns=$(sed -n '1p' "$tablename@meta")
    local data_types=$(sed -n '2p' "$tablename@meta")
    local primary_key=$(grep "PrimaryKey:" "$tablename@meta" | awk -F': ' '{print $2}') 

    # Extract column names using awk
    column_names=($(echo "$columns" | awk -F':' '{for (i=1; i<=NF; i++) print $i}'))

    # Extract data types using awk
    types_array=($(echo "$data_types" | awk -F':' '{for (i=1; i<=NF; i++) print $i}'))

    # Find the primary key column index
    local primary_index=-1
    for i in "${!column_names[@]}"; do
        if [[ "${column_names[i]}" == "$primary_key" ]]; then
            primary_index=$((i+1))
            break
        fi
    done

    if [[ $primary_index -eq -1 ]]; then
        echo "Row with primary key value $primary_key does not exist!"
        return 1
    fi

    echo
    echo "=============== Table: $tablename ==============="

    # Display column names
    echo "${column_names[*]}" | sed 's/ / | /g'
    echo 
    column -t -s ':' "$tablename"

    # Ask user for the primary key value
    echo
    read -p "Enter the primary key value of the row you want to update: " pk_value
    echo

    # Find the row with the matching primary key
    local row_number=$(awk -v pk_col="$primary_index" -v pk_val="$pk_value" -F':' '$pk_col == pk_val {print NR}' "$tablename")

    if [[ -z "$row_number" ]]; then
        echo "No row found with primary key value '$pk_value'."
        echo
        return 1
    fi

    # Read the row to be updated
    local row_content
    row_content=$(sed -n "${row_number}p" "$tablename")

    # Convert row content into an array
    IFS=':' read -ra row_values <<< "$row_content"

    # Loop through columns and ask for new values
    for ((i=0; i<${#column_names[@]}; i++)); do
        local new_value=""
        
        # Skip updating the primary key column
        if [[ $((i+1)) -eq $primary_index ]]; then
            echo "Skipping column '${column_names[i]}' ... Primary key value can not be changed."
            echo
            continue
        fi

        while true; do
            read -p "Enter new value for '${column_names[i]}' (Current value = ${row_values[i]}): " new_value
            echo

            # Validate data type
            validate_data_type "$((i+1))" "$new_value"
            if [[ $? -eq 0 ]]; then
                row_values[i]="$new_value"
                break
            fi
        done
    done

    # Join updated row values and replace the old row in the file
    local updated_row
    updated_row=$(IFS=':'; echo "${row_values[*]}")

    sed -i "${row_number}s/.*/$updated_row/" "$tablename"

    echo "Row with primary key '$pk_value' is updated successfully!"
    echo
}


update_by_column() {

    echo "Available Columns:"
    echo "=================="
    columns=$(head -1 "$tablename@meta" | tr ':' ' ' | sed 's/ / | /g' )
    echo "$columns"

    local primary_key_column=$(sed -n '3p' "$tablename@meta" | cut -d':' -f2 | tr -d ' ') 

    echo
    read -p "Enter the column name to update: " colName
    echo
    # Find column number
    colNumber=$(echo "$columns" | nl | awk -v colName="$colName" '$2 == colName {print $1}')
    
    if [[ -z "$colNumber" ]]; then
        echo "Column does not exist. Please enter a valid column name."
        echo
        return 1
    fi

    if [[ "$colName" == "$primary_key_column" ]]; then
        echo "The primary key column cannot be updated!"
        echo
        return 1
    fi

    # Ask user if they want to update based on a condition
    read -p "Do you want to update based on a condition? (y/n): " updateChoice
    echo

    if [[ "$updateChoice" =~ ^[Yy] ]]; then
        read -p "Enter the value for the condition in column $colName: " conditionValue
        echo
        read -p "Enter the new value for column $colName: " newValue
        echo

        validate_data_type "$colNumber" "$newValue" || return 1
        update_by_condition "$colNumber" "$conditionValue" "$newValue"
    else
        read -p "Enter the new value for column $colName: " newValue
        echo
        
        validate_data_type "$colNumber" "$newValue" || return 1
        update_entire_column "$colNumber" "$newValue"
    fi
}

update_by_condition() {
    local updateColumn=$1
    local conditionValue=$2
    local newValue=$3

    # Update the rows that match the condition
    awk -F: -v updateCol="$updateColumn" -v condVal="$conditionValue" -v newVal="$newValue" '
    BEGIN { OFS=":" }   
    {
        if ($updateCol == condVal) $updateCol = newVal;
        print $0;
    }' "$tablename" > temp_file && mv temp_file "$tablename"

    echo "Matching rows in column updated successfully!"
    echo
}

update_entire_column() {
    local updateColumn=$1
    local newValue=$2

    # Update all values in the column
    awk -F: -v updateCol="$updateColumn" -v newVal="$newValue" 'BEGIN { OFS=":" }
    { $updateCol = newVal; print $0 }' "$tablename" > temp_file && mv temp_file "$tablename"

    echo "All values in '$colName' are updated successfully!"
    echo
}


update_cell() {
    local tablename=$1

    # Read metadata to get column names
    local columns=$(sed -n '1p' "$tablename@meta")
    column_names=($(echo "$columns" | tr ':' ' '))

    # Read the primary key from the metadata file
    local primary_key_column=$(sed -n '3p' "$tablename@meta" | cut -d':' -f2 | tr -d ' ')

    # Ask for primary key value and check if it exists
    echo
    read -p "Enter the primary key value of the row you want to update: " primary_key
    echo

    local row_number=$(awk -F':' -v pk="$primary_key" '$1 == pk {print NR}' "$tablename")

    if [[ -z "$row_number" ]]; then
        echo "No row found with primary key '$primary_key'."
        echo
        return 1
    fi

    # Ask for the column name and check if it exists
    echo "Columns: ${column_names[*]}" | sed 's/ / | /g'
    echo "--------------------------------------"
    echo
    read -p "Enter the name of the column you want to update: " col_name
    echo


    # Check if the selected column is the primary key
    if [[ "$col_name" == "$primary_key_column" ]]; then
        echo "The primary key '$primary_key_column' cannot be changed."
        echo
        return 1
    fi

    local column_index=-1
    for i in "${!column_names[@]}"; do
        if [[ "${column_names[i]}" == "$col_name" ]]; then
            column_index=$((i+1))
            break
        fi
    done

    if [[ $column_index -eq -1 ]]; then
        echo "Column '$col_name' does not exist in table '$tablename'."
        echo
        return 1
    fi

    # Get the current cell value
    local current_value=$(awk -F':' -v row="$row_number" -v col="$column_index" 'NR == row { print $col }' "$tablename")

    # Check if the cell is empty
    if [[ -z "$current_value" ]]; then
        echo "The selected cell is empty. Please insert a value using the 'insert into table' function."
        echo
        return 1
    fi

    # Ask the user for the new value
    while true; do
    echo
        read -p "Enter the new value for '$col_name' (Current value = $current_value): " new_value
        echo

        validate_data_type "$column_index" "$new_value"
        if [[ $? -eq 0 ]]; then
            break  # Exit loop if new datatype is valid
        fi
    done

    # Ask the user for the new value
    echo
    read -p "Enter the new value for '$col_name' (Leave empty to clear it): " new_value
    echo

    # Allow the user to clear the value by entering an empty string
    if [[ -z "$new_value" ]]; then
        new_value=""  # Set it as an empty value (Null)
    else
        # Validate data type if a new value is provided
        validate_data_type "$column_index" "$new_value"
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi


    # Update the specific cell in the table
    awk -F':' -v row="$row_number" -v col="$column_index" -v new_val="$new_value" '
        BEGIN {OFS=":"}
        NR == row { $col = new_val }
        { print }
    ' "$tablename" > temp && mv temp "$tablename"

    echo "Cell updated successfully!"
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
        rm $tablename"@meta"
        echo "Table $tablename is deleted successfully!"

    done
}

#!/bin/bash
source ./lib/validation.sh
DB_PATH="./Databases"

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
    columns=$(head -1 "$tablename@meta") 
    echo "$columns" | tr ':' ' | '

    # Store column names in an array
    IFS=':' read -ra column_names <<< "$columns"

    local primary_key_column=$(sed -n '3p' "$tablename@meta" | cut -d':' -f2 | tr -d ' ') 

    echo
    read -p "Enter the column name to update: " colName
    echo

    # Find column number correctly
    colNumber=-1
    for i in "${!column_names[@]}"; do
        if [[ "${column_names[i]}" == "$colName" ]]; then
            colNumber=$((i+1)) # Adjust to 1-based index
            break
        fi
    done

    if [[ $colNumber -eq -1 ]]; then
        echo "Column '$colName' does not exist. Please enter a valid column name."
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
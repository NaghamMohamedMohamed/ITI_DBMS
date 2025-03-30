#!/bin/bash

source ./helper-functions.sh
source ./lib/validation.sh

# Function to delete a row by primary key
delete_row() 
{
    local tablename=$1

    # Load metadata: columns, data types, primary key
    read_table_metadata "$tablename"

    # Find the index of the primary key column
    local primary_key_index=-1
    for ((i=0; i<num_columns; i++)); do
        if [[ "${columns[i]}" == "$primary_key" ]]; then
            primary_key_index=$((i + 1)) # Adjust to match 1-based index
            break
        fi
    done

    # Ensure the primary key column exists
    if [[ $primary_key_index -eq -1 ]]; then
        echo "❌ Error: Primary key column '$primary_key' not found!"
        return 1
    fi

    # Prompt user for primary key value to delete
    read -p "Enter value for Primary Key ($primary_key) to delete: " pk_value

    # Get the expected data type for the primary key column
    pk_type=$(get_data_types "$tablename" | awk -F':' -v col="$primary_key_index" '{print $col}')

    # Validate data type
    if ! validate_data_type "$primary_key_index" "$pk_value"; then
        echo "❌ Invalid data type for Primary Key ($primary_key). Expected: $pk_type"
        return 1
    fi

    # Find the row number containing the primary key value
    row_num=$(awk -F':' -v pk_val="$pk_value" -v col="$primary_key_index" '$col == pk_val {print NR}' "$tablename")

    # Check if row exists
    if [[ -z "$row_num" ]]; then
        echo "⚠️ No record found with Primary Key '$pk_value'."
        return 1
    fi

    # Delete the row
    sed -i "${row_num}d" "$tablename"

    echo
    echo "✅ Row with Primary Key '$pk_value' deleted successfully."
}



# Function to delete an entire column
delete_column() 
{
    local tablename=$1

    # Read table metadata
    read_table_metadata "$tablename"

    echo "Available Columns in '$tablename' :"
    echo ======================================
    for i in "${!columns[@]}"; do
        echo "$((i+1)). ${columns[i]}"
    done

    echo
    read -p "Enter column number to delete : " col_num
    echo

    if [[ "$col_num" =~ ^[0-9]+$ ]] && (( col_num >= 1 && col_num <= num_columns )); then
        # Get the name of the column to delete
        col_to_delete="${columns[col_num-1]}"

        if [[ "$col_to_delete" == "$primary_key" ]]; then
            echo "❌ Cannot delete the primary key column."
            return 1
        fi

        # Get the index of the column to delete
        col_index=$((col_num))

    else
        echo "❌ Invalid column number."
        return 1
    fi

    # Remove the column from the data file

    # -F':' → Sets the field separator to : (since the data is stored in a colon-separated format).
    # -v col="$col_num" → Assigns the column number to be deleted (col_num) as a variable.
    # For Loop : Loop through all fields (NF means number of fields in a row).
    # if (i != col) : Skip the column that needs to be deleted. This ensures that the specified column (col_num) is not included in
    #  the output.

    # printf "%s%s", $i, (i<NF ? ":" : "\n") : Print the remaining columns while maintaining the correct format.
    # %s%s → Prints the field value $i followed by a separator.
    # (i<NF ? ":" : "\n") → If the current field is not the last one, print a :; otherwise, print a new line.

    # Final Step :
    # Redirect the modified content to a temporary file ("$tablename.tmp").
    # Replace the original table file with the modified one (mv "$tablename.tmp" "$tablename").
    # This ensures that the table is updated with the column removed.


    awk -F':' -v col="$col_index" '{
        for (i=1; i<=NF; i++) 
            if (i != col) printf "%s%s", $i, (i<NF ? ":" : "\n")
    }' "$tablename" > "$tablename.tmp" && mv "$tablename.tmp" "$tablename"

    # Remove only the selected column from the column names (Line 1)
    # -i : Edit the file in place
    # 1s/.../.../ is a substitution command (s/old/new/).
    # The 1 before s/ means apply the substitution only on line 1 (which contains column names in tablename@meta).
    # \( \) : Saves part of the text to reuse later.
    # \([^:]*:\)\{$((col_index-1))\} : Capture everything before the column to delete.
    # [^:]*: Matches the column itself (which we delete).
    # \1 : Keeps the part before the column, removing only the selected column.

    sed -i "1s/\(\([^:]*:\)\{$((col_index-1))\}\)[^:]*:/\1/" "$tablename@meta"

    # Remove only the selected column from the data types (Line 2)
    sed -i "2s/\(\([^:]*:\)\{$((col_index-1))\}\)[^:]*:/\1/" "$tablename@meta"

    echo "✅ Column '$col_to_delete' is deleted successfully!"
}



# Function to delete a specific cell value and replace it with NULL
delete_cellValue() 
{
    local tablename=$1

    # Read table metadata
    read_table_metadata "$tablename"

    echo "Available Columns in '$tablename' :"
    echo "======================================"
    for i in "${!columns[@]}"; do
        echo "$((i+1)). ${columns[i]}"
    done

    echo
    read -p "Enter column number to update : " col_num
    echo

    # Validate column number input
    if [[ ! "$col_num" =~ ^[0-9]+$ ]] || (( col_num < 1 || col_num > num_columns )); then
        echo "❌ Invalid column number."
        return 1
    fi

    # Get the column name
    col_to_modify="${columns[col_num-1]}"

    # Prevent modifying the primary key column
    if [[ "$col_to_modify" == "$primary_key" ]]; then
        echo "❌ Cannot modify the primary key column."
        return 1
    fi

    col_index=$((col_num))

    # Ask for the cell value to replace with NULL
    read -p "Enter the cell value to replace with 'NULL' : " search_value
    echo

    # Validate data type before proceeding
    if ! validate_data_type "$col_index" "$search_value"; then
        echo "❌ Invalid data type for column '$col_to_modify'."
        return 1
    fi

    # Check if the value exists in the column before replacing it
    value_exists=$(awk -F':' -v col="$col_index" -v val="$search_value" '$col == val { print "found"; exit }' "$tablename")

    if [[ "$value_exists" != "found" ]]; then
        echo "⚠️ The entered value '$search_value' does not exist in column '$col_to_modify'."
        return 1
    fi

    # Replace the specific value with NULL in the file
    awk -F':' -v col="$col_index" -v val="$search_value" '{
        for (i=1; i<=NF; i++) 
            printf "%s%s", (i == col && $i == val ? "NULL" : $i), (i<NF ? ":" : "\n")
    }' "$tablename" > "$tablename.tmp" && mv "$tablename.tmp" "$tablename"

    echo "✅ Value '$search_value' in column '$col_to_modify' is replaced with NULL ssuccessfully."
}
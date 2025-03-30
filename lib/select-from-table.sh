#!/bin/bash

source ./helper-functions.sh
source ./lib/validation.sh

# A function to display table select options
select_from_table()
{
    # If table selection fails, exit
    get_table || return  
  
    while true; do
        echo
        echo "==========================="
        echo "  Select From Table Menu "
        echo "==========================="
        echo "1) Select a specific row ( by Primary Key )."
        echo "2) Select a specific column."
        echo "3) Select a specific row by cell value."
        echo "4) Exit."
        echo
        read -p "Enter your choice : " choice
        echo

        case $choice in
            1) select_row "$tablename" ;;
            2) select_column "$tablename" ;;
            3) select_by_cellValue "$tablename" ;;
            4) echo "Returning to the previous sub-menu...";  
                sleep 1
                clear
                return ;;
            *) echo "❌ Invalid choice. Please try again." echo ;;
        esac
    done
}


# Function to select a row by primary key
select_row() 
{
    local tablename=$1
    
    # Load table metadata
    read_table_metadata "$tablename"

    # Find the primary key index
    local pk_index=-1
    for i in "${!columns[@]}"; do
        if [[ "${columns[i]}" == "$primary_key" ]]; then
            # 1-based index
            pk_index=$((i + 1))  
            break
        fi
    done

    if [[ $pk_index -eq -1 ]]; then
        echo "❌ Error: Primary key not found!"
        return
    fi

    read -p "Enter value for Primary Key ($primary_key) : " pk_value
    echo

    # Search for the row with the given primary key
    row=$(awk -F':' -v pk_val="$pk_value" -v col="$pk_index" '$col == pk_val {print $0}' "$tablename")

    if [[ -z "$row" ]]; then
        echo "❌ No record found with primary key '$pk_value'."
    else
        # Convert row into an array
        IFS=':' read -r -a row_array <<< "$row"

        echo "✅ Selected Row (Primary Key : $pk_value) :"
        echo
        echo "$(echo "${columns[*]}" | sed 's/ / | /g')"

        # Generate a dynamic separator line with multiplier ( 10 ) for column width
        separator=$(printf '%0.s-' $(seq 1 $((num_columns * 8)))) 
        echo "$separator"

        echo "${row_array[*]}" | sed 's/ / | /g'

    fi
}


# Function to select a column by its name ( through its number from the numbering list of columns )
select_column() 
{
    local tablename=$1
    
    # Load table metadata
    read_table_metadata "$tablename"

    echo "Available Columns in '$tablename' : "
    echo ======================================
    for i in "${!columns[@]}"; do
        echo "$((i+1)). ${columns[i]}"
    done

    echo
    read -p "Enter column number to select : " col_num
    echo

    if [[ "$col_num" =~ ^[0-9]+$ ]] && (( col_num >= 1 && col_num <= ${#columns[@]} )); then
        col_name="${columns[col_num-1]}"
        echo "✅ Column '$col_name' values :"
        echo
        awk -F':' -v col="$col_num" '{print $col}' "$tablename"
    else
        echo "❌ Invalid column number."
    fi
}


# Function to select rows based on a specific cell value
select_by_cellValue() 
{
    local tablename=$1

    read -p "Enter value to search for : " search_value
    echo

    # Search for the value in any column
    result=$(awk -F':' -v val="$search_value" '
        { 
            for (i=1; i<=NF; i++) { 
                if ($i == val) { print NR, $0; break } 
            } 
        }' "$tablename")

    if [[ -z "$result" ]]; then
        echo "⚠️ No matching records found."
    else
        local columns=($(sed -n '1p' "$tablename@meta" | tr ':' ' '))
        # Convert row into an array
        IFS=':' read -r -a row_array <<< "$row"

        echo "✅ Matching Records for '$search_value' :"
        echo
        # The space beofre the echo value is for alignment ( As the row number is printed at the beggining of each row )
        echo "    $(echo "${columns[*]}" | sed 's/ / | /g')"

        # Generate a dynamic separator line with multiplier ( 10 ) for column width
        separator=$(printf '%0.s-' $(seq 1 $((num_columns * 8)))) 
        echo "$separator"

        echo "${result[*]}" | sed 's/ / | /g'
    fi
}


# A function to display table deletion options
delete_from_table()
{
    # If table selection fails, exit
    get_table || return   
 
    while true; do
        echo
        echo "==========================="
        echo "  Delete From Table Menu "
        echo "==========================="
        echo "1) Delete Row."
        echo "2) Delete Column."
        echo "3) Delete a specific cell value ( Replacing with Null )."
        echo "4) Exit."
        echo
        read -p "Enter your choice : " choice
        echo

        case $choice in
            1) delete_row "$tablename" ;;
            2) delete_column "$tablename" ;;
            3) delete_cellValue "$tablename" ;;
            4) echo "Returning to the previous sub-menu...";  
                sleep 1
                clear
                return ;;
            *) echo "❌ Invalid choice. Please try again." echo ;;
        esac
    done
            
}
#!/bin/bash


DB_PATH="./Databases"

# Function to validate DB/Table name before creation
validate_name() 
{
    # A local variable to store the db/table name passed as an argument to this fucntion
    local name="$1"

    # Replace the space in the DB/Table name with underscore ( _ )
    name="${name// /_}"

    # Validate database/table name
    if [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        return 0
    fi

    return 1

}


# Function to validate DB existence before creation
db_isExist()
{
    # Convert db/table name to lowercase
    local dbname_lower=$(echo "$dbname" | tr '[:upper:]' '[:lower:]')

    #loops through the existing dBs and convert each dB name to lowercase to compare with the entered name
    for existing_db in "$DB_PATH"/*; do
        existing_db_name=$(basename "$existing_db" | tr '[:upper:]' '[:lower:]')
        if [[ "$existing_db_name" == "$dbname_lower" ]]; then
            export existing_db
            # The dB exists
            return 0  
        fi
    done
   
    return 1
}


# Function to validate Table existence before creation
table_isExist()
{
    # Convert db/table name to lowercase
    local tablename_lower=$(echo "$tablename" | tr '[:upper:]' '[:lower:]')

    # Loops through the existing tabless and convert each dB name to lowercase to compare with the entered name
    for existing_table in "$DB_PATH/$DB_NAME"/*; do
        existing_table_name=$(basename "$existing_table" | tr '[:upper:]' '[:lower:]')
        if [[ "$existing_table_name" == "$tablename_lower" ]]; then
            export existing_table
            # The table exists
            return 0  
        fi
    done
   
    return 1
}


# Function to validate column existence before creation
col_isExist()
{
    # Convert db/table name to lowercase
    local colname_lower=$(echo "$col_name" | tr '[:upper:]' '[:lower:]')

    #loops through the existing dBs and convert each dB name to lowercase to compare with the entered name
    for existing_cols in "$DB_PATH"/$DB_NAME*; do
        existing_col_name=$(basename "$existing_cols" | tr '[:upper:]' '[:lower:]')
        if [[ "$existing_col_name" == "$colname_lower" ]]; then
            export existing_col
            # The column exists
            return 0  
        fi
    done
   
    return 1
}

# Function to read the data types of the columns in a table from the @meta file
get_data_types() 
{
    local tablename=$1
    local data_type=$(sed -n '2p' "$tablename"@meta)
    echo "$data_type"
}

# Function to validate the data type of the column
validate_data_type() 
{
    local col_number=$1
    local new_value=$2
    # local data_type=$(get_data_types "$tablename")
    local data_type=$(sed -n '2p' "$tablename@meta")
    col_type=$(echo "$data_type" | awk -F':' -v col="$col_number" '{print $col}')
    
    case $col_type in
        "Int")
            if ! [[ "$new_value" =~ ^[0-9]+$ ]]; then
                echo "Invalid input. This column can only contain numerical values."
                echo
                return 1
            fi
            ;;
        "String")
            ;;
        *)
            echo "Unregistered data type."
            echo
            return 1
            ;;
    esac
    return 0
}
#!/bin/bash
source ./lib/table-menu.sh
source ./lib/validation.sh
DB_PATH="./Databases"

# Function to create a new database
create_db() 
{
    # Check if the main database directory exists, if not, it is created
    if [[ ! -d $DB_PATH ]]; then
        mkdir -p "$DB_PATH"
    fi

    while true; do
        read -p "Enter the name of the database or press 'q' to quit : " dbname

        # Check if user wants to quit
        if [[ $dbname == "q" ]]; then
            echo "Exiting database creation..."
            break
        fi

        # Check if input is empty
        if [[ -z "$dbname" ]]; then
            echo "Error: Database name cannot be empty! Please enter a valid name."
            # Restart loop
            continue  
        fi

        # Validate database name and check if it exists
        
        # Replace the space in the DB name with underscore ( _ )
        dbname="${dbname// /_}"

        validate_db "$dbname"
        case $? in
            0) 
                echo "Database '$dbname' already exists!"
                echo ;;
            1)
                mkdir "$DB_PATH/$dbname"
                echo
                echo "Database '$dbname' is created successfully!"
                break
                ;;
        esac
    done
}



# Function to list all databases
list_db() 
{
    # Checking if the databases directory exists
    if [[ ! -d $DB_PATH ]]; then
        echo "Error: Database directory '$DB_PATH' not found!"
        return 1
    fi

    # Listing only directories
    databases=$(find "$DB_PATH" -mindepth 1 -maxdepth 1 -type d | sed "s|$DB_PATH/||")
    # mindepth 1 : so it doesnt display the parent directory
    # maxdepth 1 : so it doesnt display the subdirectories only child directories
    # type d : only directories not files
    # sed : to replace the path from the output with empty string
    if [[ -z "$databases" ]]; then
        echo "No Databases Found!"
    else
        echo "List of Databases:"
        i=1
        # Loop through each database and number it
        echo "$databases" | while read db; do
            echo "$i. $db"
            ((i++))
        done
    fi
}


# Function to connect to a database ( then calls table operations menu )
connect_to_db() 
{
    read -p "Enter the database name to connect : " db_name

    # Validate database name and check if it exists
    validate_db "$db_name"
    case $? in
        1)
            echo "Database '$db_name' is not found!"
            echo ;;
        0) 
            cd "$DB_PATH/$db_name"
            echo
            echo "Connected successfully to '$db_name' database. You are now inside its folder."

            sleep 1
            sub_menu ;;
    esac
}



# Function to drop/delete a database
drop_db() 
{
    read -p "Enter database name to delete: " dbName
    echo

    # Validate database name
    validate_db "$dbName"
    case $? in
        1)
            echo "Database '$dbName' is not found!"
            echo ;;
        0) 
            while true; do
                read -p "Are you sure you want to delete '$dbName'? (y/n) : " confirm
                echo
                case "$confirm" in
                    [Yy]) 
                        rm -r "$DB_PATH/$dbName"
                        echo "Database '$dbName' is deleted successfully."
                        break
                        ;;
                    [Nn]) 
                        echo "Deletion is cancelled."
                        break
                        ;;
                    *) 
                        echo "Invalid input. Please enter 'y' for Yes or 'n' for No.";;
                esac
            done
            ;;
    esac
}



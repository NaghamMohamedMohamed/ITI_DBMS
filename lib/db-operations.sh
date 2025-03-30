#!/bin/bash
source ./lib/table-menu.sh
source ./lib/validation.sh
DB_PATH="./Databases"

#-----------------Function to create a new database-----------------
create_db() 
{
    # Check if the main database directory exists, if not, it is created
    if [[ ! -d $DB_PATH ]]; then
        mkdir -p "$DB_PATH"
    fi

    while true; do
        read -p "Enter the name of the database or press 'q' to quit : " dbname

        # Check if user wants to quit
        if [[ $dbname == "q" || $dbname == "Q" ]]; then
            echo "Exiting database creation..."
            break
        fi

        # Check if input is empty
        if [[ -z "$dbname" ]]; then
            echo "Database name cannot be empty! Please enter a valid name."
            # Restart loop
            continue  
        fi

        dbname="${dbname// /_}"

        # Validate database name and check if it exists
        validate_name "$dbname"
        case $? in
            0) 
                echo
                echo "Invalid database name. It must start with a letter and contain only letters, numbers, and underscores."
                return ;;
        esac

        db_isExist "$dbname"
        case $? in
            0) 
                echo "Database '$existing_db' already exists!"
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

#------------------Function to list all databases------------------
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

#--------------------Function to connect to a database ( then calls table operations menu )------------------
connect_to_db() {
    # Check if databases exist
    if [[ ! -d "$DB_PATH" || -z "$(ls -A "$DB_PATH")" ]]; then
        echo "No databases available to connect to."
        return 1
    fi

    while true; do
        echo "Available Databases:"
        echo "===================="

        # List databases with numbers
        db_list=($(ls -1 "$DB_PATH")) # Store databases in an array
        for i in "${!db_list[@]}"; do
            echo "$((i+1)). ${db_list[i]}"
        done

        echo "===================="
        echo
        read -p "Enter the number of the database to connect to (or press 'q' to exit): " choice

        # Exit if user presses 'q' or 'Q'
        if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
            echo "Operation is canceled."
            return 0
        fi

        # Validate input (must be a number within range)
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#db_list[@]} )); then
            DB_NAME="${db_list[choice-1]}" # Set the chosen database as active
            cd "$DB_PATH/$DB_NAME"
            echo
            echo "Connected successfully to '$DB_NAME' database. You are now inside its folder."
            echo

            # Make DB_NAME accessible in other files
            export DB_NAME 
            sleep 2
            # Navigate to table menu
            sub_menu
            return 0
        else
            echo
            echo "Invalid choice! Please enter a valid number or 'q' to exit."
            echo
        fi
    done
}

#----------------Function to drop/delete a database-----------------
drop_db() {
    # Check if there are any databases
    if [[ ! -d "$DB_PATH" || -z "$(ls -A "$DB_PATH")" ]]; then
        echo "No databases available to drop."
        return 1
    fi

    while true; do
        echo "Available Databases:"
        echo "===================="

        # List databases with numbers
        db_list=($(ls -1 "$DB_PATH")) # Store databases in an array
        for i in "${!db_list[@]}"; do
            echo "$((i+1)). ${db_list[i]}"
        done

        echo "===================="
        echo
        read -p "Enter the number of the database to drop (or press 'q' to exit): " choice
        echo

        # Check if user wants to quit
        if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
            echo "Operation is canceled."
            return 0
        fi

        # Validate input (must be a number within range)
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#db_list[@]} )); then
            db_to_delete="${db_list[choice-1]}"
            
            # Confirm deletion
            read -p "Are you sure you want to delete '$db_to_delete'? (y/n): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                rm -r "$DB_PATH/$db_to_delete"
                echo "Database '$db_to_delete' deleted successfully!"
            else
                echo "Operation is canceled."
            fi
            return 0
        else
            echo
            echo "Invalid choice! Please enter a valid number or 'q' to exit."
            echo 
        fi
    done
}





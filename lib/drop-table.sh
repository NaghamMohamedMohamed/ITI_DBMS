#!/bin/bash
source ./lib/validation.sh
DB_PATH="./Databases"

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
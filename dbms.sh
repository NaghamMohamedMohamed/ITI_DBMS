#!/bin/bash  

# Import the database functions
source ./lib/db-operations.sh 

# Function to display the main menu
function main_menu
{
    while true ; do
        echo "======================"
        echo "Bash DBMS - Main Menu "
        echo "======================"
        echo "1) Create a Database."
        echo "2) List All Databases."
        echo "3) Connect To a Database."
        echo "4) Drop a Database."
        echo "5) Exit."
        echo 
        read -p "Enter your choice : " choice
        echo

        case $choice in 
            1) create_db ;;
            2) list_db ;;
            3) connect_to_db ;;
            4) drop_db ;;
            5) echo "Exiting The DBMS ..."; exit 0 ;;
            *) echo "Invalid choice. Please try again." ;;
        esac       
        echo  
    done
}

# Call the function to be runned upon running this file
main_menu

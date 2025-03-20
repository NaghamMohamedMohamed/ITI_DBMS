#!/bin/bash  

# Import the tables & records functions
source ./lib/tables-operations.sh 
source ./lib/records-columns-operations.sh


#cThe sub menu for table , records , columns operations after connecting to specific DB

function sub_menu
{
    while true ; do
        echo "======================"
        echo "Bash DBMS - Sub Menu "
        echo "======================"
        echo "1) Create a Table."
        echo "2) List All Tables."
        echo "3) Update a Table."
        echo "4) Drop a Table."
        echo "5) Insert a Record/Column into a Table."
        echo "6) Select a Record/Column From a Table."
        echo "7) Delete a Record/Column From a Table."
        echo "8) Exit."
        echo 
        read -p "Enter your choice : " choice
        echo

        case $choice in 
            1) create_table ;;
            2) list_tables ;;
            3) update_table ;;
            4) drop_table ;;
            5) insert_into_table ;;
            6) select_from_table ;;
            7) delete_from_table ;;
            8) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid choice. Please try again." ;;
        esac       
        echo  
    done
}
# **Bash Shell Script Database Management System (DBMS)**  

![DBMS CLI](https://img.shields.io/badge/Bash-Shell%20Scripting-blue)  
A simple **Database Management System (DBMS)** built using **Bash scripting**, enabling users to create, manage, and manipulate databases and tables via a command-line interface (CLI).  

---

## 🚀 **Project Overview**  
This project provides a **menu-driven** interface to manage databases and tables using shell scripts. Users can **create, retrieve, update, and delete (CRUD) data** stored on disk. The system ensures data integrity by handling **primary keys, data types, and structured storage**.  

---

## 📌 **Features**  

### **🛢️ Database Management**  
- Create a new database.  
- List all existing databases.  
- Connect to a database.  
- Drop a database.  

### **📋 Table Management**  
- Create a new table with specified columns and data types.  
- List all tables within a database. 
- Update all values in specific row. 
- Update a whole column values. 
   - Options : 
      1. With condition : Update all cells having specific value in this column.
      2. Without condition : Update the entire column values with one new value.
- Update a specific old cell value with new value.
- Drop a table.  

### **📊 Data Manipulation**  
- Insert new rows into a table while enforcing **data type validation** 
- Insert new empty column ( Intialized with Null Values ). 
- Insert a new value in an empty cell.
- Select a row conatining the entered primary key value.
- Select a whole specific column.
- Select rows containing specific value ( not primary key ).
- Delete a specific row with a certain primary key value.
- Delete a whole column.
- Delete specific cell value in a certain column ( replacing with `NULL` value ).  
 
### **🛠️ Validation**
- Databases , Tables , Columns names validation.
- Databases , Tables , Columns existence validation.
- Columns data types validation.

### **❓ Helper Functions**
- Get table based on user choice table number from the numbering list.
- Read the table metadata data ( column names , data types ) from the @meta file.



---

### **📂 Folders & Files Structure**  

The project is organized into the following directories and files:  

1. **Databases Folder** (`Databases/`) :  
   - When a table is created, two files are generated inside the respective database folder :  
     - **`@meta`** : Stores column names, data types (separated by **":"**), and the primary key column name on a new line.  
     - **Data File** : Stores table records, where values are separated by **":"**, and each row is stored on a new line.  

2. **`helper_functions.sh`** : Contains utility functions used across different scripts.  

3. **`dbms.sh`** ( Entry Point ) : The main script that initiates the Database Management System.  

4. **`lib/` Folder** : Contains modular script files for :  
   - **Menu Displays** :  
     - `main_menu.sh` – Handles database operations.  
     - `table_menu.sh` – Manages table operations.  
   - **Operation Functions** : Each script in this folder corresponds to a specific database , table or table data ( records , columns  ,cells ) operations (create, update, delete, etc.).  
    - **Validation Functions**.



---

## 🔧 **How It Works**  

1️⃣ Run the script:  
   ```bash
   ./dbms.sh
   ```  
2️⃣ Navigate through the CLI-based **menu system** to perform operations.  
3️⃣ Data is stored as **directories and files**, simulating a database structure.  
4️⃣ **Validations** ensure correct data entry (e.g., primary keys must be unique & non-null).  

---

## 📜 **Implementation Details**  

✅ **Database Representation**  
- Databases are stored as **directories** within the script’s directory.  
- Tables are stored as **files**, where each row is a line and values are delimited.  

✅ **Table Structure**  
   - Metadata (`@meta` file) stores **column names, data types, and primary keys**.  
   - Data validation is performed **before insertion or updates**.  

✅ **Row Selection**  
   - `SELECT` operations display results in a **well-formatted table-like output**.  

✅ **Error Handling**  
   - Ensures **primary keys are unique** and **data types match column definitions**.  
   - Handles incorrect user inputs with appropriate messages.  

---

## 🛠 **Installation & Setup**  

1. **Clone the Repository**  
   ```bash
   git clone https://github.com/NaghamMohamedMohamed/ITI_DBMS.git
   cd bash-dbms
   ```  

2. **Grant Execution Permissions**  
   ```bash
   chmod +x dbms.sh
   ```  

3. **Run the Script**  
   ```bash
   ./dbms.sh
   ```    

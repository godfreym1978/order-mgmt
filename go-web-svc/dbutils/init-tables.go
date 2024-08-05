/* File: init-tables.go

Description:
 Initiates the connection to databases and also creates the backend table for mysql to persist the records in the table
*/

package dbutils

import (
	"database/sql"
	"log"
)

func Initialize(dbDriver *sql.DB) {
	statement, driverError := dbDriver.Prepare(inventory)
	if driverError != nil {
		log.Println(driverError)
	}

	// Create table
	_, statementInvError := statement.Exec()

	if statementInvError != nil {
		log.Println("Table already exists!")
	}

	statement, driverError = dbDriver.Prepare(customer)
	if driverError != nil {
		log.Println("statementError", driverError)
	}
	// Create table
	_, statementCustError := statement.Exec()

	if statementCustError != nil {
		log.Println("Table already exists!")
	}

	statement, driverError = dbDriver.Prepare(orders)
	if driverError != nil {
		log.Println("statementError", driverError)
	}
	// Create table
	_, statementOrderError := statement.Exec()

	if statementOrderError != nil {
		log.Println("Table already exists!")
	}

	log.Println("All tables created/initialized successfully!")
}

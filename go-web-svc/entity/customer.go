/* File: orders.go

Description:
 Specification of the Orders struct to define the json data structure.
*/

package entity

type Customer struct {
	ID    uint   `json:"cust_id,omitempty"`
	FName string `json:"cust_fname"`
	LName string `json:"cust_lname"`
	City  string `json:"cust_city"`
	State string `json:"cust_state"`
}

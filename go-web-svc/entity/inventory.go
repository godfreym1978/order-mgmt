/* File: orders.go

Description:
 Specification of the Orders struct to define the json data structure.
*/

package entity

type Inventory struct {
	ID       uint   `json:"prod_id,omitempty"`
	ProdName string `json:"prod_name"`
	Supplier string `json:"prod_supplier"`
	Price    uint   `json:"prod_unit_price"`
	Stock    uint   `json:"prod_unit_stock"`
}

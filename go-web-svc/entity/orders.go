/* File: orders.go

Description:
 Specification of the Orders struct to define the json data structure.
*/

package entity

type Orders struct {
	ID      uint   `json:"order_id,omitempty"`
	CustID  uint   `json:"order_cust_id"`
	ProdID  uint   `json:"order_prod_id"`
	Qty     uint   `json:"order_qty"`
	Details string `json:"order_dtl"`
}

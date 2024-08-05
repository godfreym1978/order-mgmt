/* File: employee.go

Description:
 Specification of the Employee struct to define the json data structure.
*/

package entity

import (
	"gopkg.in/mgo.v2/bson"
)

type Product struct {
	ID              bson.ObjectId `json:"id" bson:"_id,omitempty"`
	ProdName        string        `json:"prodname" bson:"prodname"`
	ProdDescription string        `json:"proddesc" bson:"proddesc"`
	Services        string        `json:"services" bson:"services"`
	Region          string        `json:"region" bson:"region"`
}

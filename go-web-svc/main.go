/* File: main.go

Description:
 This is the main file to start the application. Its also used to route the requests as defined in here.
*/

package main

import (
	"order-mgmt-go-websvc/dbutils"

	"github.com/gin-gonic/gin"
)

func main() {
	router := gin.Default()

	/*
		router.GET("/", func(ctx *gin.Context) {
			ctx.JSON(http.StatusOK, gin.H{"data": "Hello World!"})
		})
	*/

	// if there is an error opening the connection, handle it
	db := createDBConn()

	dbutils.Initialize(db)

	v1 := router.Group("/api/v1")
	{
		v1.POST("/customer", CreateCustomer)
		v1.GET("/customers", GetCustomers)

		v1.POST("/inventory", CreateInventory)
		v1.GET("/inventory", GetInventory)

		v1.GET("/orders", GetOrders)

		v1.GET("/orders/:id", GetOrder)
		v1.POST("/order", CreateOrder)

		v1.POST("/product", PutProduct)
		v1.GET("/products", GetProducts)
		v1.GET("/product", GetProduct)

		/*
			v1.PUT("/orders/:id", UpdateUser)
			v1.DELETE("/orders/:id", DeleteUser)

		*/
	}

	router.Run(":8080")
}

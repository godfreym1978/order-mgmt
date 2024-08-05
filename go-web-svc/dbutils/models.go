package dbutils

const orders = `
CREATE TABLE IF NOT EXISTS orders (
order_id INTEGER NOT NULL AUTO_INCREMENT,
order_cust_id INTEGER ,
order_prod_id INTEGER,
order_qty INTEGER,
order_dtl VARCHAR(100) NULL,
PRIMARY KEY(order_id),
FOREIGN KEY(order_cust_id) REFERENCES customer(cust_id),
FOREIGN KEY(order_prod_id) REFERENCES inventory(prod_id)
)
`
const customer = `
CREATE TABLE IF NOT EXISTS customer (
cust_id INTEGER AUTO_INCREMENT,
cust_fname VARCHAR(100),
cust_lname VARCHAR(100),
cust_city VARCHAR(100),
cust_state VARCHAR(2),
PRIMARY KEY(cust_id)
)
`
const inventory = `
CREATE TABLE IF NOT EXISTS inventory (
prod_id INTEGER AUTO_INCREMENT,
prod_name VARCHAR(100) ,
prod_supplier VARCHAR(100) ,
prod_unit_price INTEGER,
prod_unit_stock INTEGER,
PRIMARY KEY(prod_id)
)
`

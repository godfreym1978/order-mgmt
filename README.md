This repo contains 3 parts -

go-web-svc
-----------
It contains the GO REST application that accesses the MongoDB and MySQL backe end database.
The configuration to connect to the backend databases need to be changed in the go-web-svc/config/config.yaml file  
Once the application starts it will create the required tables in the MySQL database. Use either these insert statements or the dump file in source-db-dump directory to check the application responses.

A sample data for the tables
insert into inventory ( prod_name, prod_supplier, prod_unit_price, prod_unit_stock)  
values ("Google Cloud", "Google", 10, 100) ,
("AWS", "Amazon", 10, 100) ,
("Azure", "Microsoft", 10, 100) ,
("Windows", "Microsoft", 10, 100);

insert into customer (cust_fname, cust_lname, cust_city, cust_state)  
values ("Jeff", "Bezos", "Redmond", "WA"),  
("Bill", "Gates", "Redmond", "WA"),
("Sundar", "Pichai", "San Francisco", "CA");


google-cloud
------------
It contains the terraform scripts to create the infrastructure to mimic the OnPrem and GCP environment. The dev.tfvars needs to be changed as your environment.


confluent-kafka
---------------
It contains the terraform script to create the confluent environment. The configuration needs to be change in the dev.tfvars as per your Source MongoDB and MySQL configuration.
The topic-schemas folder contains the schemas required for the topics from mongodb and mysql.

CREATE DATABASE finance;

USE finance;
--
-- Table structure for table `inventory`
--

DROP TABLE IF EXISTS `inventory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `inventory` (
          `prod_id` int(11) NOT NULL AUTO_INCREMENT,
          `prod_name` varchar(100) DEFAULT NULL,
          `prod_supplier` varchar(100) DEFAULT NULL,
          `prod_unit_price` int(11) DEFAULT NULL,
          `prod_unit_stock` int(11) DEFAULT NULL,
          PRIMARY KEY (`prod_id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventory`
--

LOCK TABLES `inventory` WRITE;
/*!40000 ALTER TABLE `inventory` DISABLE KEYS */;
INSERT INTO `inventory` VALUES
(1,'Google Cloud','Google',10,100),
(2,'AWS','Amazon',10,100),
(3,'Azure','Microsoft',10,100),
(4,'Windows','Microsoft',10,100);
/*!40000 ALTER TABLE `inventory` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `customer`
--

DROP TABLE IF EXISTS `customer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `customer` (
          `cust_id` int(11) NOT NULL AUTO_INCREMENT,
          `cust_fname` varchar(100) DEFAULT NULL,
          `cust_lname` varchar(100) DEFAULT NULL,
          `cust_city` varchar(100) DEFAULT NULL,
          `cust_state` varchar(2) DEFAULT NULL,
          PRIMARY KEY (`cust_id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `customer`
--

LOCK TABLES `customer` WRITE;
/*!40000 ALTER TABLE `customer` DISABLE KEYS */;
INSERT INTO `customer` VALUES
(1,'Jeff','Bezos','Redmond','WA'),
(2,'Bill','Gates','Redmond','WA'),
(3,'Sundar','Pichai','San Francisco','CA'),
(4,'Jane','Doe','Dallas','TX');
/*!40000 ALTER TABLE `customer` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `orders` (
          `order_id` int(11) NOT NULL AUTO_INCREMENT,
          `order_cust_id` int(11) DEFAULT NULL,
          `order_prod_id` int(11) DEFAULT NULL,
          `order_qty` int(11) DEFAULT NULL,
          `order_dtl` varchar(100) DEFAULT NULL,
          PRIMARY KEY (`order_id`),
          KEY `order_cust_id` (`order_cust_id`),
          KEY `order_prod_id` (`order_prod_id`),
          CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`order_cust_id`) REFERENCES `customer` (`cust_id`),
          CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`order_prod_id`) REFERENCES `inventory` (`prod_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
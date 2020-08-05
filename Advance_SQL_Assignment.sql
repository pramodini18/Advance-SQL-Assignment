-- Creating Database:
create database vision_international;

-- use database:
use vision_international;

-- 1. Write an SQL script to create the tables and set constraints based on the given ER diagram. 
-- Also define the indexes as specified in the ER Diagram.

-- creating tables as per ER diagram:
-- 1. Customer table:
create table Customer(
Id int not null,
FirstName nvarchar(40),
LastName nvarchar(40),
City nvarchar(40),
Country nvarchar(40),
Phone nvarchar(20),
primary key(Id),
index IndexCustomerName(FirstName,LastName));

-- 2. Order table:

create table `Order`(
Id int not null primary key,
OrderDate datetime,
OrderNumber nvarchar(10),
CustomerId int,
TotalAmount decimal(12,2),
FOREIGN KEY(CustomerId) REFERENCES Customer(Id),
index IndexOrderCustomerId(CustomerId),
index IndexOrderOrderDate(OrderDate));


-- 3. OrderItem Table:

create table OrderItem(
Id int not null primary key,
OrderId int,
ProductId int,
UnitPrice decimal(12,2),
Quantity int,
FOREIGN KEY(OrderId) REFERENCES `Order`(Id),
index IndexOrderItemOrderId(OrderId),
index IndexOrderItemProductId(ProductId));

-- 4. Product Table:

create table Product(
Id int not null primary key,
ProductName nvarchar(50),
SupplierId int,
UnitPrice decimal(12,2),
Package nvarchar(30),
IsDiscontinued bit,
index IndexProductSupplierId(SupplierId),
index IndexProductName(ProductName));

-- 5. Supplier:

create table Supplier(
Id int not null primary key,
CompanyName nvarchar(40),
ContactName nvarchar(50),
ContactTitle nvarchar(40),
City nvarchar(40),
Country nvarchar(40),
Phone nvarchar(30),
Fax nvarchar(30),
index IndexSupplierName(CompanyName),
index IndexSupplierCountry(Country));

alter table Product
add foreign key(SupplierId) references Supplier(Id);

alter table OrderItem
add foreign key(ProductId) references Product(Id);


-- Note: Before executing second question - please run data script to load the data into table.

-- 2. The company wants to identify suppliers who are responsible for the highest revenue. 
-- This data would have to be regularly accessed.
-- I have added one more column - IsDiscontinued. This is to make sure to see few products are discontinued.(I have asked about this questions in forum too).

create view supplier_revenue as
select p.SupplierId as `Supplier ID`, p.id as `Product ID`, 
sum((o.unitprice * o.Quantity)) as `Revenue`, p.IsDiscontinued
from  product p
inner join orderitem o
on p.id = o.productId
group by p.SupplierId, p.id
order by Revenue desc;

-- I have added one more column - IsDiscontinued. 
-- This is to make sure to see few products are discontinued.(I have asked about this questions in forum too).
select * from supplier_revenue;


-- 3.Write SQL transactions for the following activities:
-- a.Adding a new customer to the database.

-- Enabling the autocommit mode explicitly:
SET autocommit = 1;

START TRANSACTION;

-- Get the latest ID number
SELECT @CID:=MAX(ID)+1
from customer;
	
-- insert a new customer 
insert into customer(Id, FirstName, LastName, City, Country, Phone)
values(@CID, 'Priya', 'Varun', 'Reggio Emilia', 'Italy', 555750);

-- commit changes
commit;


-- b.Updating a new order into the database.
-- Here because the question is ambiguous : 
-- 1. Updating 'new' record. Because the word 'new' is used- does it mean inserting new record?
-- 2. Because they have used the word 'updating' - I will update one of the existing records.
-- I have addressed both the scenario.

-- In case you want to run the transaction: uncomment the below commands:
-- delete from orderitem where orderId = 831;
-- delete from `order` where id = 831;
-- delete from customer where id = 92;


-- 1. First instance - inserting new record to order table.(first case)

START TRANSACTION;

-- Get the latest order ID number
SELECT @OID:=MAX(Id)+1
from `Order`;

-- Get the latest order number for order table
SELECT @ONum:=MAX(OrderNumber)+1
from `order`;

-- inserting a new order for our newly added customer id = 92
insert into `Order`(Id, OrderDate, OrderNumber, CustomerId, TotalAmount)
values(@OID, SYSDATE(), @ONum, @CID, 80.5);

-- As new item is inserted in order table - it effects OrderItem table too
-- So let us make the changes in orderItem table too

-- Get the latest orderitem id
SELECT @OIID1:=MAX(Id)+1
from `OrderItem`;

SELECT @OIID2 :=(@OIID1)+1
from `OrderItem`;

-- Getting the unitprice from product table
-- Assumption: Product id as 14 and 60 and quantity = 2 and 1 respectively 
SELECT @P1 := UnitPrice from product where Id = 14;
SELECT @P2 := UnitPrice from product where Id = 60;

-- Inserting two products to orderitem table for the same orderId - @OID
insert into `OrderItem`(Id, OrderId, ProductId, UnitPrice, Quantity)
values(@OIID1, @OID, 14, @P1, 2),(@OIID2, @OID, 60, @P2, 1);

-- commit changes
commit;

-- Disabling the autocommit mode explicitly:
SET autocommit = 0;


-- b.Updating a new order into the database.
-- 2. Because they have used the word 'updating' - I will update one of the existing records. (second case)
-- Let us try updating totalamount of customerId = 92/order id = 831

-- Enabling the autocommit mode explicitly:
SET autocommit = 1;

START TRANSACTION;

-- Let us update order item table and eventually calculate total amount 
-- Assumption : orderId = 831 and updating quantity =2 for productid = 60
update orderitem
set Quantity =3
where productId = 60 and OrderId = 831;

-- calculating total amount
select @totalprice := sum(Quantity * UnitPrice)
from orderitem
where OrderId = 831
group by OrderId;

-- Updating the order table with calculated total amount from above
Update `order`
set TotalAmount = @totalprice 
where Id = 831;

-- commit changes
commit;

-- Disabling the autocommit mode explicitly:
SET autocommit = 0;


-- 4. Vision International ltd. also intends to send out promotional
-- offers to customers who have placed orders amounting to more than 5000. 
-- Identify the names of these customers

select concat(c.FirstName,' ',c.LastName) as `Customer Name`, 
count(o.Id) as `No of Orders`, sum(o.TotalAmount) as `Total order Value`
from customer c
inner join `order` o
on c.Id = o.CustomerId
group by o.CustomerId
having `Total order Value` > 5000
order by `Total order Value` desc;

-- 5. Identify those customers who are responsible for at least 10 orders 
-- with the 'average order value' being greater than 1000.

select concat(c.FirstName,' ',c.LastName) as `Customer Name`, 
count(o.Id) as `No of Orders`, sum(o.TotalAmount) as `Total order Value`, 
avg(o.TotalAmount) as `Average order value`
from customer c
inner join `order` o
on c.Id = o.CustomerId
group by o.CustomerId
having `No of Orders` >= 10 and `Average order value` >1000
order by `Average order value` desc;



drop table if exists dwh.calendar_dim;

CREATE TABLE dwh.calendar_dim
(
 date_id      int NOT NULL,
 year         int NOT NULL,
 quarter      int NOT NULL,
 month        int NOT NULL,
 week         int NOT NULL,
 week_day     varchar(20) NOT NULL,
 "date"         date NOT NULL,
 is_leap_year boolean NOT NULL,
 CONSTRAINT PK_calendar_dim PRIMARY KEY ( date_id )
);

truncate table dwh.calendar_dim;

insert into dwh.calendar_dim 
select 
to_char(date,'yyyymmdd')::int as date_id,  
       extract('year' from date)::int as year,
       extract('quarter' from date)::int as quarter,
       extract('month' from date)::int as month,
       extract('week' from date)::int as week,
       to_char(date, 'dy') as week_day,
       date::date,
       CASE WHEN extract('month' from date) = 1 and extract('day' from date) = 1 and extract('day' from (date + interval '2 month - 1 day')) = 29 THEN true
            ELSE false
       end as is_leap_year
  from generate_series(date '2016-01-01',
                       date '2030-01-01',
                       interval '1 day')
       as t(date);
      
--checking
select * from dwh.calendar_dim 
limit 10;

--SHIPPING

--creating a table
drop table if exists dwh.shipping_dim ;

CREATE TABLE dwh.shipping_dim
(
 ship_id       serial NOT NULL,
 ship_mode varchar(14) NOT NULL,
 CONSTRAINT PK_shipping_dim PRIMARY KEY ( ship_id )
);

--deleting rows
truncate table dwh.shipping_dim;

--generating ship_id and inserting ship_mode from orders
insert into dwh.shipping_dim 
select 100+row_number() over(), ship_mode from (select distinct ship_mode from public.orders ) a;
--checking
select * from dwh.shipping_dim; 


--GEO

--creating a table
drop table if exists dwh.geo_dim ;

CREATE TABLE dwh.geo_dim
(
 geo_id      int NOT NULL,
 country     varchar(50) NOT NULL,
 "state"       varchar(50) NULL,
 city        varchar(50) NOT NULL,
 postal_code varchar(16) NOT NULL,
 CONSTRAINT PK_geo_dim PRIMARY KEY ( geo_id )
);

--deleting rows
truncate table dwh.geo_dim;

--inserting geo data from orders
insert into dwh.geo_dim 
select 100+row_number() over(), country, state, city, postal_code  from (select distinct country, state, city, coalesce(postal_code,0) as postal_code from public.orders ) a;
--checking
select * from dwh.geo_dim; 


--CUSTOMERS

--creating a table
drop table if exists dwh.customers_dim ;

CREATE TABLE dwh.customers_dim
(
 cust_id       int NOT NULL,
 customer_id   varchar(10) NOT NULL,
 customer_name varchar(50) NOT NULL,
 segment       varchar(50) NOT NULL,
 CONSTRAINT PK_customers_dim PRIMARY KEY ( cust_id )
);


--deleting rows
truncate table dwh.customers_dim;

--inserting geo data from orders
insert into dwh.customers_dim 
select 100+row_number() over(), customer_id, customer_name, segment  from (select distinct customer_id, customer_name, segment from public.orders ) a;
--checking
select * from dwh.customers_dim; 


--MANGERS

--creating a table
drop table if exists dwh.managers_dim ;

CREATE TABLE dwh.managers_dim
(
 manager_id   int NOT NULL,
 manager_name varchar(50) NOT NULL,
 region       varchar(50) NOT NULL,
 CONSTRAINT PK_managers_dim PRIMARY KEY ( manager_id )
);

--deleting rows
truncate table dwh.managers_dim;

--inserting geo data from orders
insert into dwh.managers_dim 
select 100+row_number() over(), manager_name, region  from (select distinct person as manager_name, region from stg.orders ) a;
--checking
select * from dwh.managers_dim; 


--PRODUCTS

--creating a table
drop table if exists dwh.products_dim ;

CREATE TABLE dwh.products_dim
(
 product_id   varchar(24) NOT NULL,
 category     varchar(50) NOT NULL,
 subcategory varchar(50) NOT NULL,
 product_name varchar(150) NOT NULL,
 CONSTRAINT PK_products_dim PRIMARY KEY ( product_id )
);
--deleting rows
truncate table dwh.products_dim;

--inserting geo data from orders
insert into dwh.products_dim 
select product_id, category, subcategory, product_name   from (select distinct product_id, category, subcategory, product_name from stg.orders ) a;
--checking
select * from dwh.products_dim; 


--SALES
drop table if exists dwh.sales_fact ;

CREATE TABLE dwh.sales_fact
(
 row_id        int NOT NULL,
 order_id      varchar(50) NOT NULL,
 order_date_id int NOT NULL,
 ship_date_id  int NOT NULL,
 ship_id       int NOT NULL,
 manager_id    int NOT NULL,
 cust_id       int NOT NULL,
 geo_id        int NOT NULL,
 product_id    varchar(24) NOT NULL,
 sales         numeric(15,2) NOT NULL,
 quantity      numeric(18,3) NOT NULL,
 discount      numeric(4,2) NOT NULL,
 profit        numeric(19,4) NOT NULL,
 CONSTRAINT PK_sales_fact PRIMARY KEY ( row_id ),
 CONSTRAINT FK_61 FOREIGN KEY ( ship_id ) REFERENCES dwh.shipping_dim ( ship_id ),
 CONSTRAINT FK_64 FOREIGN KEY ( manager_id ) REFERENCES dwh.managers_dim ( manager_id ),
 CONSTRAINT FK_67 FOREIGN KEY ( cust_id ) REFERENCES dwh.customers_dim ( cust_id ),
 CONSTRAINT FK_70 FOREIGN KEY ( geo_id ) REFERENCES dwh.geo_dim ( geo_id ),
 CONSTRAINT FK_73 FOREIGN KEY ( product_id ) REFERENCES dwh.products_dim ( product_id )
);

CREATE INDEX fkIdx_62 ON dwh.sales_fact
(
 ship_id
);

CREATE INDEX fkIdx_65 ON dwh.sales_fact
(
 manager_id
);

CREATE INDEX fkIdx_68 ON dwh.sales_fact
(
 cust_id
);

CREATE INDEX fkIdx_71 ON dwh.sales_fact
(
 geo_id
);

CREATE INDEX fkIdx_74 ON dwh.sales_fact
(
 product_id
);

--deleting rows
truncate table dwh.sales_fact;

--inserting geo data from orders
insert into dwh.sales_fact 
select
	 100+row_number() over() as row_id
	 ,o.order_id
	 ,to_char(o.order_date,'yyyymmdd')::int as  order_date_id
	 ,to_char(o.ship_date,'yyyymmdd')::int as  ship_date_id
	 ,s.ship_id
	 ,md.manager_id
	 ,cd.cust_id 
	 ,g.geo_id
	 ,p.product_id
	 ,o.sales
	 ,o.quantity
	 ,o.discount
	 ,o.profit
from stg.orders o 
inner join dwh.shipping_dim s on o.ship_mode = s.ship_mode
inner join dwh.geo_dim g on (CASE WHEN o.postal_code is null THEN '0' ELSE o.postal_code::text  END) = g.postal_code and g.country=o.country and g.city = o.city and o.state = g.state --City Burlington doesn't have postal code
inner join dwh.products_dim p on o.product_name = p.product_name and o.subcategory=p.subcategory and o.category=p.category and o.product_id=p.product_id 
inner join dwh.customers_dim cd on cd.customer_id=o.customer_id and cd.customer_name=o.customer_name and cd.segment=o.segment
inner join dwh.managers_dim md on md.manager_name=o.person and md.region=o.region;

--checking
--do you get 9994rows? 
select count(*) from dwh.sales_fact sf
inner join dwh.shipping_dim s on sf.ship_id=s.ship_id
inner join dwh.geo_dim g on sf.geo_id=g.geo_id
inner join dwh.products_dim p on sf.product_id=p.product_id
inner join dwh.customers_dim cd on sf.cust_id=cd.cust_id;
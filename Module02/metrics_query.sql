--TotalSales
select sum(sales) from dwh.sales_fact sf;

--Total Profit
select sum(profit) from dwh.sales_fact sf;

--Profit Ratio
select sum(profit)/coalesce(sum(sales),1) * 100 as profit_ratio  from dwh.sales_fact sf;

--Profit per Order
select order_id, sum(profit) as order_profit from dwh.sales_fact sf
group by order_id 
order by order_id;

--Sales and Profit by Customer
select cd.customer_name, sum(sales) as cust_sales, sum(profit) as cust_profit from dwh.sales_fact sf
left join dwh.customers_dim cd on cd.cust_id = sf.cust_id 
group by cd.customer_name 
order by cust_sales desc ;

--Avg. Discount
select avg(discount) * 100 from dwh.sales_fact sf;

--Monthly Sales by Segment
select cd.segment, cd2."year", cd2."month", sum(sales) from dwh.sales_fact sf 
left join dwh.customers_dim cd on cd.cust_id = sf.cust_id 
left join dwh.calendar_dim cd2 on cd2.date_id = sf.order_date_id 
group by cd.segment, cd2."year", cd2."month"
order by cd.segment, cd2."year", cd2."month" ;

--Monthly Sales by Product Category
select pd.category, cd2."year", cd2."month", sum(sales) from dwh.sales_fact sf 
left join dwh.products_dim pd on pd.product_id = sf.product_id 
left join dwh.calendar_dim cd2 on cd2.date_id = sf.order_date_id 
group by pd.category, cd2."year", cd2."month"
order by pd.category, cd2."year", cd2."month" ;

--Sales by Product Category over time
select pd.category, sum(sales) from dwh.sales_fact sf 
left join dwh.products_dim pd on pd.product_id = sf.product_id 
group by pd.category
order by pd.category;

--Sales per region
select md.region , sum(sales) as total_sales from dwh.sales_fact sf 
left join dwh.managers_dim md on md .manager_id = sf.manager_id
group by md.region 
order by total_sales;
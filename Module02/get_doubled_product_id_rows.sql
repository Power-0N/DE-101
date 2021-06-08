select o.row_id, o.product_id, o.product_name, o2.product_name  from stg.orders o
join stg.orders o2 on o.product_id = o2.product_id 
and o.product_name > o2.product_name
where o2.product_name notnull  
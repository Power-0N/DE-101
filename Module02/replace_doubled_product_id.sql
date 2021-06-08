UPDATE stg.orders    
SET product_id = concat(product_id,'0')    
where
row_id
in (select o.row_id from stg.orders o
join stg.orders o2 on o.product_id = o2.product_id 
and o.product_name > o2.product_name
where o2.product_name notnull);   

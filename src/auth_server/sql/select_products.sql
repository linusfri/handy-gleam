select distinct p.* 
from products p
inner join product_user_group pug on p.id = pug.product_id
where pug.user_group_id = any($1);
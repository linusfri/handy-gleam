update products
set
    name = $2,
    description = $3,
    status = $4,
    price = $5,
    updated_at = now()
where id = $1
and exists (
    select 1 from product_user_group
    where product_user_group.product_id = products.id
    and product_user_group.user_group_id = any($6)
)
returning *;

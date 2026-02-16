delete from product_file
where product_id = $1
and exists (
    select 1 from product_user_group
    where product_user_group.product_id = product_file.product_id
    and product_user_group.user_group_id = any($2)
);
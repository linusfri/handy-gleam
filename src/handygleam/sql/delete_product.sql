-- name: delete_product
-- Deletes a product by ID only if it belongs to user's groups
delete from products p
where
    p.id = $1
    and exists (
        select 1
        from product_user_group pug
        where
            pug.product_id = p.id
            and pug.user_group_id = any ($2)
    );
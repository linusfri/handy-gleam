-- name: delete_image_by_id
-- Deletes an image only if it belongs to a product in user's groups
delete from images i
where i.id = $1
and exists (
  select 1 from product_image pi
  inner join product_user_group pug on pi.product_id = pug.product_id
  where pi.image_id = i.id
  and pug.user_group_id = any($2)
);
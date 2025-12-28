-- name: delete_file_by_id
-- Deletes a file only if it belongs to a product in user's groups
delete from files i
where i.id = $1
and exists (
  select 1 from product_file pf
  inner join product_user_group pug on pf.product_id = pug.product_id
  where pf.file_id = i.id
  and pug.user_group_id = any($2)
);
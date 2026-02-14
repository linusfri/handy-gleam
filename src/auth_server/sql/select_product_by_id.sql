-- name: select_product_by_id
-- Select a product by ID only if it belongs to user's groups
select 
  products.id,
  products.name,
  products.description,
  products.status,
  products.price,
  products.created_at,
  products.updated_at,
  COALESCE(
    json_agg(
      json_build_object('id', files.id, 'filename', files.filename, 'file_type', files.file_type, 'context_type', files.context_type)
    ) filter (where files.id is not null), '[]'::json) as images,
  COALESCE(
    json_agg(
      json_build_object('platform', product_integrations.platform, 'resource_id', product_integrations.resource_id)
    ) filter (where product_integrations.id is not null and product_integrations.resource_id is not null), '[]'::json) as integrations
from products
inner join product_user_group on products.id = product_user_group.product_id
left join product_file on products.id = product_file.product_id
left join files on product_file.file_id = files.id
left join product_integrations on products.id = product_integrations.product_id
where products.id = $1
and product_user_group.user_group_id = any($2)
group by products.id, products.name, products.description, products.status, products.price, products.created_at, products.updated_at
limit 1;
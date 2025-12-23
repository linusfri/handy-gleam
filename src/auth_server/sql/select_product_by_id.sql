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
  COALESCE(array_agg(images.filename) filter (where images.filename is not null), '{}') as images
from products
inner join product_user_group on products.id = product_user_group.product_id
left join product_image on products.id = product_image.product_id
left join images on product_image.image_id = images.id
where products.id = $1
and product_user_group.user_group_id = any($2)
group by products.id, products.name, products.description, products.status, products.price, products.created_at, products.updated_at
limit 1;
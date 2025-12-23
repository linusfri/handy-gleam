-- select_products.sql
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
where product_user_group.user_group_id = any($1)
group by products.id, products.name, products.description, products.status, products.price, products.created_at, products.updated_at
order by products.id;
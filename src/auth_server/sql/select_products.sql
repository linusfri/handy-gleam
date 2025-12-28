-- select_products.sql
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
      json_build_object(
        'id',
        files.id,
        'filename',
        files.filename,
        'file_type',
        files.file_type,
        'context_type',
        files.context_type
      )
    ) filter (
      where
        files.id is not null
    ),
    '[]' :: json
  ) as images
from
  products
  inner join product_user_group on products.id = product_user_group.product_id
  left join product_file on products.id = product_file.product_id
  left join files on product_file.file_id = files.id
where
  product_user_group.user_group_id = any($1)
group by
  products.id,
  products.name,
  products.description,
  products.status,
  products.price,
  products.created_at,
  products.updated_at
order by
  products.id;
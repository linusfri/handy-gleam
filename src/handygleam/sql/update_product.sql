with updated as (
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
  returning *
)
select
  updated.id,
  updated.name,
  updated.description,
  updated.status,
  updated.price,
  updated.created_at,
  updated.updated_at,
  COALESCE(
    json_agg(
      json_build_object(
        'id', files.id,
        'filename', files.filename,
        'file_type', files.file_type,
        'context_type', files.context_type
      )
    ) filter (where files.id is not null),
    '[]'::json
  ) as images
from updated
left join product_file on updated.id = product_file.product_id
left join files on product_file.file_id = files.id
group by updated.id, updated.name, updated.description, updated.status, updated.price, updated.created_at, updated.updated_at;

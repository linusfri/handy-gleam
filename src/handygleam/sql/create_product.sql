with inserted as (
  insert into
      products (
          name,
          description,
          status,
          price,
          created_at,
          updated_at
      )
  values ($1, $2, $3, $4, now(), now())
  returning *
)
select
  inserted.id,
  inserted.name,
  inserted.description,
  inserted.status,
  inserted.price,
  inserted.created_at,
  inserted.updated_at,
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
from inserted
left join product_file on inserted.id = product_file.product_id
left join files on product_file.file_id = files.id
group by inserted.id, inserted.name, inserted.description, inserted.status, inserted.price, inserted.created_at, inserted.updated_at;
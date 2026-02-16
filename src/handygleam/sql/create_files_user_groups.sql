insert into
  file_user_group (file_id, user_group_id)
select
  *
from
  unnest(
    $1::int[],    -- file_ids
    $2::varchar[] -- user_group_ids
  )

returning id, file_id, user_group_id, created_at;
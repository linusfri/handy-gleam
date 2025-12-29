-- name: select_file_by_id
-- Get file details by ID with user_group permission check
select distinct
    files.id,
    files.filename,
    files.file_type,
    files.context_type
from files
    inner join file_user_group on files.id = file_user_group.file_id
where
    files.id = $1
    and file_user_group.user_group_id = any ($2)
    and files.deleted = false;
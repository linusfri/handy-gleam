select files.id, files.filename, files.file_type, files.context_type
from files
    inner join file_user_group on files.id = file_user_group.file_id
where
    file_user_group.user_group_id = any ($1);
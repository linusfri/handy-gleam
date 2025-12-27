-- name: select_image_by_id
-- Get file details by ID
select *
from files
where id = $1;
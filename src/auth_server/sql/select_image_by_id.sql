-- name: select_image_by_id
-- Get image details by ID
select id, filename, created_at
from images
where id = $1;
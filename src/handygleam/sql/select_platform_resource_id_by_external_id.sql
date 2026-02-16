-- name: select_platform_resource_id_by_external_id
-- Get platform_resource id by external_id and platform
select id
from platform_resources
where external_id = $1 and platform = $2
limit 1;

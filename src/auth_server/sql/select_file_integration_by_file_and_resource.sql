-- name: select_file_integration_by_file_and_resource
-- Select file integration by file_id, platform, and resource_id
select id, file_id, platform, resource_id, external_id, synced_at, metadata, created_at, updated_at
from file_integration
where file_id = $1 and platform = $2 and resource_id = $3;

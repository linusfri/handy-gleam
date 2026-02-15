-- name: select_file_integrations_by_files_and_resource
-- Select file integrations by file_ids array, platform, and resource_id
select id, file_id, platform, resource_id, external_id, synced_at, metadata, created_at, updated_at
from file_integration
where file_id = any($1::int[]) and platform = $2 and resource_id = $3;

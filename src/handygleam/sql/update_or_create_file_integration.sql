-- name: update_or_create_file_integration
-- update or create a file integration record
insert into file_integration (file_id, platform, resource_id, external_id, metadata)
values ($1, $2, $3, $4, coalesce($5::jsonb, '{}'))
on conflict (file_id, platform, resource_id)
do update set
    external_id = EXCLUDED.external_id,
    metadata = EXCLUDED.metadata,
    synced_at = now(),
    updated_at = now()

returning id, file_id, platform, resource_id, external_id, synced_at, created_at;

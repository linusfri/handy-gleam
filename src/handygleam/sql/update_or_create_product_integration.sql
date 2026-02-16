-- name: update_or_create_product_integration_external_id
-- Create or update product integration with external_id and sync status after posting to platform
insert into product_integrations (product_id, platform, external_id, sync_status, synced_at, resource_id)
values ($1, $2, $3, $4, now(), $5)
on conflict (product_id, platform)
do update set
  external_id = EXCLUDED.external_id,
  sync_status = EXCLUDED.sync_status,
  synced_at = now()
returning id, product_id, platform, resource_id, external_id, sync_status, synced_at;

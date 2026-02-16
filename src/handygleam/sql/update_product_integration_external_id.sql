-- name: update_product_integration_external_id
-- Update external_id for a product integration
update product_integrations
set 
  external_id = $1,
  sync_status = 'synced',
  synced_at = now(),
  updated_at = now()
where product_id = $2 and resource_id = $3
returning id, product_id, platform, resource_id, external_id, sync_status, synced_at;

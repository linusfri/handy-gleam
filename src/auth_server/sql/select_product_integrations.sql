-- name: select_product_integrations
-- Get product integrations by product_id
select 
  id,
  product_id,
  platform,
  resource_id,
  sync_status,
  external_id,
  synced_at
from product_integrations
where product_id = $1;
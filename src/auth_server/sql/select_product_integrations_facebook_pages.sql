-- name: select_product_integrations_facebook_pages
-- Get product integrations by product_id and resource_type 'page' for Facebook platform
select
    id,
    product_id,
    platform,
    resource_id,
    resource_type,
    sync_status,
    external_id,
    synced_at
from product_integrations
where
    product_id = $1
    and platform = 'facebook'
    and resource_type = 'page';
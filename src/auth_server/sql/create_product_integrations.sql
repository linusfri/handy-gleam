-- name: create_product_integrations
-- Insert product integrations
insert into product_integrations (product_id, platform, resource_id)
select $1, * from unnest(
  $2::integration_platform[],
  $3::varchar[]
)
returning id, product_id, platform, resource_id, sync_status;
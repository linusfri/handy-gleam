-- name: create_product_integrations
-- Insert product integrations
insert into product_integrations (product_id, platform, resource_id, resource_type)
select $1, * from unnest(
  $2::integration_platform[],
  $3::varchar[],
  $4::resource_type_enum[]
)
returning id, product_id, platform, resource_id, resource_type, sync_status;
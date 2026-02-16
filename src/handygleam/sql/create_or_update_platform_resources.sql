-- Insert or update platform resources (like Facebook pages)
INSERT INTO platform_resources (user_id, platform, resource_type, external_id, resource_name, resource_token)
SELECT 
  $1::VARCHAR,
  $2::integration_platform,
  $3::resource_type_enum,
  external_id,
  resource_name,
  resource_token
FROM unnest(
  $4::VARCHAR[],  -- external_ids
  $5::VARCHAR[],  -- resource_names
  $6::TEXT[]      -- resource_tokens
  -- able to include metadata if needed in future
) AS platform_resources(external_id, resource_name, resource_token)
ON CONFLICT (user_id, platform, resource_type, external_id) 
DO UPDATE SET 
  resource_name = EXCLUDED.resource_name,
  resource_token = EXCLUDED.resource_token,
  updated_at = CURRENT_TIMESTAMP
RETURNING id, user_id, platform, resource_type, external_id, resource_name, resource_token, metadata, created_at, updated_at;

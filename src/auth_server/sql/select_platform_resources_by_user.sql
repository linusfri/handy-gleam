-- Get all platform resources for a user on a specific platform
SELECT id, user_id, platform, resource_type, external_id, resource_name, resource_token, metadata, created_at, updated_at
FROM platform_resources
WHERE user_id = $1::VARCHAR 
  AND platform = $2::integration_platform
ORDER BY created_at DESC;

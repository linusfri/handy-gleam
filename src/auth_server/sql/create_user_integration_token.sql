-- name: create_user_integration_token :exec
INSERT INTO user_integration_tokens (user_id, platform, access_token, token_type)
VALUES ($1, $2, $3, $4)
ON CONFLICT (user_id, platform) 
DO UPDATE SET 
  access_token = EXCLUDED.access_token,
  token_type = EXCLUDED.token_type,
  updated_at = NOW();

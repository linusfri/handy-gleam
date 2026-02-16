-- name: create_user_integration_token :exec
insert into
    user_integration_tokens (
        user_id,
        platform,
        access_token,
        token_type
    )
values ($1, $2, $3, $4) on conflict (user_id, platform) do
update
set
    access_token = excluded.access_token,
    token_type = excluded.token_type,
    updated_at = now();
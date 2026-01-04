-- migrate:up
create table user_integration_tokens (
  id serial primary key,
  user_id varchar(255) not null,
  platform integration_platform not null,
  access_token text not null,
  token_type varchar(50),
  updated_at timestamp default now(),
  unique(user_id, platform)
);

create index idx_user_integration_tokens_user_id on user_integration_tokens(user_id);

-- migrate:down
drop table user_integration_tokens;

-- migrate:up
create type resource_type_enum as enum ('page');
create type integration_platform as enum ('instagram', 'facebook');

create table platform_resources (
    id serial primary key,
    user_id varchar(255) not null,
    platform integration_platform not null,
    resource_type resource_type_enum not null,
    external_id varchar(255) not null, -- For example Facebook page_id
    resource_name varchar(255), -- For example Facebook page_name
    resource_token text, -- Optional: only if resource has its own token. For example a facebook page.
    metadata jsonb, -- Extra data (followers, reach, etc.)
    created_at timestamp default now(),
    updated_at timestamp default now(),
    unique (
        user_id,
        platform,
        resource_type,
        external_id
    )
);

create index idx_platform_resources_user_platform on platform_resources (user_id, platform);

create index idx_platform_resources_external_id on platform_resources (external_id);

-- migrate:down
drop type resource_type_enum;
drop table platform_resources;
drop type integration_platform;
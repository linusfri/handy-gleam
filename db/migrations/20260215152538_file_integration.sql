-- migrate:up
create table file_integration (
    id serial primary key,
    file_id int not null references files (id) on delete cascade,
    platform integration_platform not null,
    resource_id varchar(255), -- External ID of the platform resource (e.g., Facebook page ID)
    external_id varchar(255), -- External platform file ID
    synced_at timestamp default now(),
    metadata jsonb, -- width, height, URL, etc.
    created_at timestamp default now(),
    updated_at timestamp default now(),
    unique (
        file_id,
        platform,
        resource_id
    )
);

-- migrate:down
drop table file_integration;

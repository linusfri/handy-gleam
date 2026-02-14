-- migrate:up
create type integration_platform as enum ('instagram', 'facebook');
create type sync_status as enum ('pending', 'synced', 'failed');

create table product_integrations (
  id serial primary key,
  product_id int not null references products(id) on delete cascade,
  platform integration_platform not null,
  resource_id varchar(255),
  synced_at timestamp,
  sync_status sync_status not null default 'pending',
  external_id varchar(255),
  metadata jsonb,
  created_at timestamp default now(),
  updated_at timestamp default now(),
  unique(product_id, platform)
);

-- migrate:down
drop table product_integrations;

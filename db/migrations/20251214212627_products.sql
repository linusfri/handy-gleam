-- migrate:up
create type product_status as enum (
  'sold',
  'available'
);

create table products (
    id serial primary key,
    name varchar(255) not null,
    description text,
    status product_status not null,
    price numeric(10,2) not null,
    created_at timestamp default current_timestamp,
    updated_at timestamp default current_timestamp
);

-- migrate:down
drop table products;

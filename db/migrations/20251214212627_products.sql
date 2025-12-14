-- migrate:up
create table products (
    id serial primary key,
    name varchar(255) not null,
    description text,
    created_at timestamp default current_timestamp,
    updated_at timestamp default current_timestamp
);

-- migrate:down
drop table products;

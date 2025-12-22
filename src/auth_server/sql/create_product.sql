insert into products (name, description, status, price, created_at, updated_at) values
    ($1, $2, $3, $4, now(), now()) returning id;
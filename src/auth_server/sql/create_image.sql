insert into images (filename, created_at)
values ($1, now())
returning id;
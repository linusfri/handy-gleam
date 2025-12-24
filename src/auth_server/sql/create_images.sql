insert into images (filename, created_at)
select unnest($1::text[]), now()
returning id, filename;
insert into files (filename, file_type, context_type)
select * from unnest(
  $1::text[],              -- filenames
  $2::file_type_enum[],    -- file_types (MIME types)
  $3::context_type_enum[]  -- context_types context_type_enum 
)
returning id, filename, file_type, context_type;
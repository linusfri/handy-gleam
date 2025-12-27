import auth_server/sql
import gleam/option.{type Option}

pub type File {
  File(
    id: Option(Int),
    data: Option(String),
    filename: String,
    file_type: String,
    context_type: sql.ContextTypeEnum,
  )
}

pub type CreatedFile {
  CreatedFile(
    filename: String,
    file_type: String,
    context_type: sql.ContextTypeEnum,
  )
}

import auth_server/lib/file/transform.{type FileType}
import auth_server/sql
import gleam/option.{type Option}

pub type File {
  File(
    id: Option(Int),
    data: Option(String),
    filename: String,
    file_type: FileType,
    context_type: sql.ContextTypeEnum,
  )
}

pub type CreatedFile {
  CreatedFile(
    filename: String,
    file_type: FileType,
    context_type: sql.ContextTypeEnum,
  )
}

pub type User {
  User(
    sub: String,
    email_verified: Bool,
    name: String,
    groups: List(String),
    preferred_username: String,
    given_name: String,
    family_name: String,
    email: String,
  )
}

import auth_server/auth/types.{User}
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode

pub fn user_decoder(json_data: Dynamic) {
  let user_decoder = {
    use sub <- decode.field("sub", decode.string)
    use email_verified <- decode.field("email_verified", decode.bool)
    use name <- decode.field("name", decode.string)
    use preferred_username <- decode.field("preferred_username", decode.string)
    use given_name <- decode.field("given_name", decode.string)
    use family_name <- decode.field("family_name", decode.string)
    use email <- decode.field("email", decode.string)

    decode.success(User(
      sub: sub,
      email_verified: email_verified,
      name: name,
      preferred_username: preferred_username,
      given_name: given_name,
      family_name: family_name,
      email: email,
    ))
  }

  decode.run(json_data, user_decoder)
}

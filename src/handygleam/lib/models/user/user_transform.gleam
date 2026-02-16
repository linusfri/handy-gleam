import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json
import handygleam/lib/models/user/user_types.{
  type FacebookUser, type User, FacebookUser, User,
}

pub fn user_decoder(json_data: Dynamic) {
  let user_decoder = {
    use sub <- decode.field("sub", decode.string)
    use email_verified <- decode.field("email_verified", decode.bool)
    use name <- decode.field("name", decode.string)
    use preferred_username <- decode.field("preferred_username", decode.string)
    use groups <- decode.field("groups", decode.list(decode.string))
    use given_name <- decode.field("given_name", decode.string)
    use family_name <- decode.field("family_name", decode.string)
    use email <- decode.field("email", decode.string)

    decode.success(User(
      sub: sub,
      email_verified: email_verified,
      name: name,
      preferred_username: preferred_username,
      groups: groups,
      given_name: given_name,
      family_name: family_name,
      email: email,
    ))
  }

  decode.run(json_data, user_decoder)
}

pub fn user_encoder(user: User) -> json.Json {
  json.object([
    #("sub", json.string(user.sub)),
    #("email_verified", json.bool(user.email_verified)),
    #("name", json.string(user.name)),
    #("preferred_username", json.string(user.preferred_username)),
    #("given_name", json.string(user.given_name)),
    #("family_name", json.string(user.family_name)),
    #("email", json.string(user.email)),
  ])
}

pub fn facebook_user_to_json(facebook_user: FacebookUser) -> json.Json {
  let FacebookUser(id:, name:) = facebook_user
  json.object([
    #("id", json.string(id)),
    #("name", json.string(name)),
  ])
}

pub fn facebook_user_decoder(dynamic_user: dynamic.Dynamic) {
  let facebook_user_decoder = {
    use id <- decode.field("id", decode.string)
    use name <- decode.field("name", decode.string)
    decode.success(FacebookUser(id:, name:))
  }

  decode.run(dynamic_user, facebook_user_decoder)
}

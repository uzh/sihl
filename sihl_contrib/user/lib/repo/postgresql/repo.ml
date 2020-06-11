module Sql = struct
  module Model = Sihl_user.Repo_sig.User

  module User = struct
    let get_all connection =
      let module Connection = (val connection : Caqti_lwt.CONNECTION) in
      let request =
        Caqti_request.find Caqti_type.unit Model.t
          {sql|
        SELECT 
          uuid as @string{id}, 
          @string{email}, 
          @string?{username}, 
          @string{password},
          @string{status},
          @bool{admin},
          @bool{confirmed}
        FROM user_users
        |sql}
      in
      Connection.collect_list request ()

    let get connection =
      let module Connection = (val connection : Caqti_lwt.CONNECTION) in
      let request =
        Caqti_request.find Caqti_type.string Model.t
          {sql|
        SELECT 
          uuid as @string{id}, 
          @string{email}, 
          @string?{username}, 
          @string{password},
          @string{status},
          @bool{admin},
          @bool{confirmed}
        FROM user_users
        WHERE user_users.uuid = %string{id}
        |sql}
      in
      Connection.find request

    let get_by_email connection =
      let module Connection = (val connection : Caqti_lwt.CONNECTION) in
      let request =
        Caqti_request.find Caqti_type.string Model.t
          {sql|
        SELECT 
          uuid as @string{id}, 
          @string{email}, 
          @string?{username}, 
          @string{password},
          @string{status},
          @bool{admin},
          @bool{confirmed}
        FROM user_users
        WHERE user_users.email = %string{email}
        |sql}
      in
      Connection.find request

    let insert connection =
      let module Connection = (val connection : Caqti_lwt.CONNECTION) in
      let request =
        Caqti_request.exec Model.t
          {sql|
        INSERT INTO user_users (
          uuid, 
          email, 
          username, 
          password,
          status,
          admin,
          confirmed
        ) VALUES (
          %string{id}, 
          %string{email}, 
          %string?{username}, 
          %string{password},
          %string{status},
          %bool{admin},
          %bool{confirmed}
        )
        |sql}
      in
      Connection.exec request

    let update connection =
      let module Connection = (val connection : Caqti_lwt.CONNECTION) in
      let request =
        Caqti_request.exec Model.t
          {sql|
        UPDATE user_users
        SET 
          email = %string{email}, 
          username = %string?{username}, 
          password = %string{password},
          status = %string{status},
          admin = %bool{admin},
          confirmed = %bool{confirmed}
        WHERE user_users.uuid = %string{id}
        |sql}
      in
      Connection.exec request

    let clean connection =
      let module Connection = (val connection : Caqti_lwt.CONNECTION) in
      let request =
        Caqti_request.exec Caqti_type.unit
          {sql|
        TRUNCATE TABLE user_users CASCADE;
                                            |sql}
      in
      Connection.exec request ()
  end

  module Token = struct
    module Model = Sihl_user.Repo_sig.Token

    let get connection =
      let module Connection = (val connection : Caqti_lwt.CONNECTION) in
      let request =
        Caqti_request.find Caqti_type.string Model.t
          {sql|
        SELECT 
          user_tokens.uuid as @string{id}, 
          user_tokens.token_value as @string{value},
          user_users.uuid as @string{user},
          user_tokens.kind as @string{kind},
          user_tokens.status as @string{status}
        FROM user_tokens
        LEFT JOIN user_users 
        ON user_users.id = user_tokens.token_user
        WHERE user_tokens.token_value = %string{value}
        |sql}
      in
      Connection.find request

    let insert connection =
      let module Connection = (val connection : Caqti_lwt.CONNECTION) in
      let request =
        Caqti_request.exec Model.t
          {sql|
        INSERT INTO user_tokens (
          uuid, 
          token_value,
          token_user,
          kind,
          status
        ) VALUES (
          %string{id}, 
          %string{value},
          (SELECT id FROM user_users WHERE user_users.uuid = %string{user}),
          %string{kind},
          %string{status}
        )
        |sql}
      in
      Connection.exec request

    let update connection =
      let module Connection = (val connection : Caqti_lwt.CONNECTION) in
      let request =
        Caqti_request.exec Model.t
          {sql|
        UPDATE user_tokens 
        SET 
          token_value = %string{value},
          token_user = 
          (SELECT id FROM user_users 
           WHERE user_users.uuid = %string{user}),
          kind = %string{kind},
          status = %string{status}
        WHERE user_tokens.uuid = %string{id}
        |sql}
      in
      Connection.exec request

    let delete_by_user connection =
      let module Connection = (val connection : Caqti_lwt.CONNECTION) in
      let request =
        Caqti_request.exec Caqti_type.string
          {sql|
        DELETE FROM user_tokens 
        WHERE user_tokens.token_user = 
        (SELECT id FROM user_users 
         WHERE user_users.uuid = %string{id})
        |sql}
      in
      Connection.exec request

    let clean connection =
      let module Connection = (val connection : Caqti_lwt.CONNECTION) in
      let request =
        Caqti_request.exec Caqti_type.unit
          {sql|
        TRUNCATE TABLE user_tokens CASCADE;
        |sql}
      in
      Connection.exec request ()
  end
end

module Migration = struct
  let create_users_table =
    Sihl.Repo.Migration.Postgresql.migrate
      {sql|
CREATE TABLE user_users (
  id serial,
  uuid uuid NOT NULL,
  email VARCHAR(128) NOT NULL,
  password VARCHAR(128) NOT NULL,
  username VARCHAR(128),
  status VARCHAR(128) NOT NULL,
  admin BOOLEAN NOT NULL DEFAULT false,
  confirmed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE (uuid),
  UNIQUE (email)
);
|sql}

  let create_tokens_table =
    Sihl.Repo.Migration.Postgresql.migrate
      {sql|
CREATE TABLE user_tokens (
  id serial,
  uuid uuid NOT NULL,
  token_value VARCHAR(128) NOT NULL,
  token_user INTEGER,
  status VARCHAR(128) NOT NULL,
  kind VARCHAR(128) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE (token_value),
  UNIQUE (uuid),
  FOREIGN KEY (token_user) REFERENCES user_users (id)
);
|sql}

  (* TODO this should be a seed that this app call on startup *)
  let add_confirmation_template =
    Sihl.Repo.Migration.Postgresql.migrate
      {sql|
        INSERT INTO email_templates (
          uuid,
          label,
          content_text,
          content_html,
          status
        ) VALUES (
          'fb7aec3f-2178-4166-beb4-79a3a663e093',
          'registration_confirmation',
          'Hi, \n\n Thanks for signing up. \n\n Please go to this URL to confirm your email address: {base_url}/app/confirm-email?token={token} \n\n Best, \n Josef',
          '',
          'active'
        )
|sql}

  (* TODO this should be a seed that this app call on startup *)
  let add_password_reset_template =
    Sihl.Repo.Migration.Postgresql.migrate
      {sql|
        INSERT INTO email_templates (
          uuid,
          label,
          content_text,
          content_html,
          status
        ) VALUES (
          'fb7aec3f-2178-4166-beb4-79a3a663e092',
          'registration_confirmation',
          'Hi, \n\n You requested to reset your password. \n\n Please go to this URL to reset your password: {base_url}/app/password-reset?token={token} \n\n Best, \n Josef',
          '',
          'active'
        )
|sql}

  let migration () =
    ( "user",
      [
        ("create users table", create_users_table);
        ("create tokens table", create_tokens_table);
        ("add confirmation email template", add_confirmation_template);
        ("add password reset email template", add_password_reset_template);
      ] )
end

module User = struct
  let get_all connection = Sql.User.get_all connection

  let get ~id connection = Sql.User.get connection id

  let get_by_email ~email connection = Sql.User.get_by_email connection email

  let insert user connection = Sql.User.insert connection user

  let update user connection = Sql.User.update connection user
end

module Token = struct
  let get ~value connection = Sql.Token.get connection value

  let delete_by_user ~id connection = Sql.Token.delete_by_user connection id

  let insert token connection = Sql.Token.insert connection token

  let update token connection = Sql.Token.update connection token
end

let migrate = Migration.migration

let clean connection =
  let ( let* ) = Lwt_result.bind in
  let* () = Sql.User.clean connection in
  Sql.Token.clean connection

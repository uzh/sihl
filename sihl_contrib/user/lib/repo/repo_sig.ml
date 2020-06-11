module type REPOSITORY = sig
  include Sihl.Core.Contract.REPOSITORY

  module User : sig
    val get_all :
      Sihl.Core.Db.connection -> Sihl.User.t list Sihl.Core.Db.db_result

    val get :
      id:string -> Sihl.Core.Db.connection -> Sihl.User.t Sihl.Core.Db.db_result

    val get_by_email :
      email:string ->
      Sihl.Core.Db.connection ->
      Sihl.User.t Sihl.Core.Db.db_result

    val insert :
      Sihl.User.t -> Sihl.Core.Db.connection -> unit Sihl.Core.Db.db_result

    val update :
      Sihl.User.t -> Sihl.Core.Db.connection -> unit Sihl.Core.Db.db_result
  end

  module Token : sig
    val get :
      value:string ->
      Sihl.Core.Db.connection ->
      Model.Token.t Sihl.Core.Db.db_result

    val delete_by_user :
      id:string -> Sihl.Core.Db.connection -> unit Sihl.Core.Db.db_result

    val insert :
      Model.Token.t -> Sihl.Core.Db.connection -> unit Sihl.Core.Db.db_result

    val update :
      Model.Token.t -> Sihl.Core.Db.connection -> unit Sihl.Core.Db.db_result
  end
end

module User = struct
  open Sihl.User

  let t =
    let encode m =
      Ok
        ( m.id,
          ( m.email,
            (m.username, (m.password, (m.status, (m.admin, m.confirmed)))) ) )
    in
    let decode
        (id, (email, (username, (password, (status, (admin, confirmed)))))) =
      Ok { id; email; username; password; status; admin; confirmed }
    in
    Caqti_type.(
      custom ~encode ~decode
        (tup2 string
           (tup2 string
              (tup2 (option string)
                 (tup2 string (tup2 string (tup2 bool bool)))))))
end

module Token = struct
  open Model.Token

  let t =
    let encode m = Ok (m.id, (m.value, (m.kind, (m.user, m.status)))) in
    let decode (id, (value, (kind, (user, status)))) =
      Ok { id; value; kind; user; status }
    in
    Caqti_type.(
      custom ~encode ~decode
        (tup2 string (tup2 string (tup2 string (tup2 string string)))))
end

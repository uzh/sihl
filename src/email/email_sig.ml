module Template = struct
  module type SERVICE = sig
    include Core_container.SERVICE

    val get :
      Core.Ctx.t ->
      id:string ->
      (Email_core.Template.t option, string) Result.t Lwt.t

    val get_by_name :
      Core.Ctx.t ->
      name:string ->
      (Email_core.Template.t option, string) Result.t Lwt.t

    val create :
      Core.Ctx.t ->
      name:string ->
      html:string ->
      text:string ->
      (Email_core.Template.t, string) Result.t Lwt.t

    val update :
      Core.Ctx.t ->
      template:Email_core.Template.t ->
      (Email_core.Template.t, string) Result.t Lwt.t

    val render :
      Core.Ctx.t -> Email_core.t -> (Email_core.t, string) Result.t Lwt.t
  end

  module type REPO = sig
    include Data.Repo.Sig.REPO

    val get :
      id:string ->
      Data_db_core.connection ->
      (Email_core.Template.t option, string) Result.t Lwt.t

    val get_by_name :
      name:string ->
      Data_db_core.connection ->
      (Email_core.Template.t option, string) Result.t Lwt.t

    val insert :
      Data_db_core.connection ->
      template:Email_core.Template.t ->
      (unit, string) Result.t Lwt.t

    val update :
      Data_db_core.connection ->
      template:Email_core.Template.t ->
      (unit, string) Result.t Lwt.t
  end
end

module ConfigProvider = struct
  module type SMTP = sig
    val smtp_host : Core.Ctx.t -> (string, string) Lwt_result.t

    val smtp_port : Core.Ctx.t -> (int, string) Lwt_result.t

    val smtp_secure : Core.Ctx.t -> (bool, string) Lwt_result.t
  end

  module type SENDGRID = sig
    val api_key : Core.Ctx.t -> (string, string) Lwt_result.t
  end
end

module type SERVICE = sig
  include Core_container.SERVICE

  val send : Core.Ctx.t -> Email_core.t -> (unit, string) Result.t Lwt.t
end

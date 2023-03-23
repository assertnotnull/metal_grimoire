defmodule MetalGrimoire.Repo do
  use Ecto.Repo,
    otp_app: :metal_grimoire,
    adapter: Ecto.Adapters.Postgres
end

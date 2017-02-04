defmodule Rumbl.Repo.Migrations.FixTypoAnnotationAtColumn do
  use Ecto.Migration

  def change do
    rename table(:annotations), :as, to: :at
  end
end

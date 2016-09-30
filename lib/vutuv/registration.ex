defmodule Vutuv.Registration do
  import Ecto.Query
  alias Vutuv.User
  alias Vutuv.Slug
  alias Vutuv.Repo
  alias Vutuv.SearchTerm

  def register_user(conn, user_params, assocs \\ []) do
    slug =
      if(user_params["first_name"] != nil or user_params["last_name"] != nil) do
        struct = %User{first_name: user_params["first_name"], last_name: user_params["last_name"]}

        slug_value = generate_slug(struct)

        Slug.changeset(%Slug{}, %{value: slug_value})
      end
    search_terms = SearchTerm.create_search_terms(user_params)
    changeset = User.changeset(%User{}, user_params)
    |> Ecto.Changeset.put_assoc(:slugs, [slug])
    |> Ecto.Changeset.put_assoc(:search_terms, search_terms)
    |> Ecto.Changeset.put_change(:active_slug, slug.changes.value)
    |> Ecto.Changeset.put_change(:locale, conn.assigns[:locale])
    changeset = 
    Enum.reduce([changeset | assocs], fn {type, params}, changeset ->
      changeset
      |>Ecto.Changeset.put_assoc(type, [params])
    end)
     Repo.insert(changeset)
  end

  def generate_slug(user) do
    slug_value = Slugger.slugify_downcase(user, ?.)

    f = fn val -> if val, do: val, else: "" end

    user_count = Repo.one(from u in User,
      where: u.first_name == ^f.(user.first_name)
      and u.last_name == ^f.(user.last_name),
      select: count("*"))
    
    if(user_count>0) do
      slug_value<>Integer.to_string(user_count)
    else
      slug_value
    end
  end
end
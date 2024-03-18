defmodule ClonetrollerTest do
  use ExUnit.Case, async: true
  doctest Clonetroller

  defmodule Router do
    use Phoenix.Router

    @compile {:no_warn_undefined, ResourceController}

    resources "/resources", ResourceController

    scope "/admin" do
      resources "/resources", ResourceController
    end
  end

  defmodule Resource do
    @behaviour Clonetroller
    import Clonetroller, only: [clone: 2]

    clone Router, ResourceController

    @impl Clonetroller
    def request(verb, path, request, meta) do
      {verb, path, request, meta}
    end
  end

  setup do
    [req: %{ref: make_ref()}]
  end

  describe "basic clone" do
    test "index", %{req: req} do
      assert {:get, path, ^req, meta} = Resource.index(req)
      assert path == "/resources"
      assert meta == %{controller: ResourceController, path: "/resources", path_params: []}
    end

    test "new", %{req: req} do
      assert {:get, path, ^req, meta} = Resource.new(req)
      assert path == "/resources/new"
      assert meta == %{controller: ResourceController, path: "/resources/new", path_params: []}
    end

    test "create", %{req: req} do
      assert {:post, path, ^req, meta} = Resource.create(req)
      assert path == "/resources"
      assert meta == %{controller: ResourceController, path: "/resources", path_params: []}
    end

    test "show", %{req: req} do
      id = 3 |> :crypto.strong_rand_bytes() |> Base.url_encode64()

      assert {:get, path, ^req, meta} = Resource.show(id, req)
      assert path == "/resources/#{id}"

      assert meta == %{
               controller: ResourceController,
               path: "/resources/:id",
               path_params: [id: id]
             }
    end

    test "edit", %{req: req} do
      id = 3 |> :crypto.strong_rand_bytes() |> Base.url_encode64()

      assert {:get, path, ^req, meta} = Resource.edit(id, req)
      assert path == "/resources/#{id}/edit"

      assert meta == %{
               controller: ResourceController,
               path: "/resources/:id/edit",
               path_params: [id: id]
             }
    end

    test "update", %{req: req} do
      id = 3 |> :crypto.strong_rand_bytes() |> Base.url_encode64()

      assert {:patch, path, ^req, meta} = Resource.update(id, req)
      assert path == "/resources/#{id}"

      assert meta == %{
               controller: ResourceController,
               path: "/resources/:id",
               path_params: [id: id]
             }
    end

    test "delete", %{req: req} do
      id = 3 |> :crypto.strong_rand_bytes() |> Base.url_encode64()

      assert {:delete, path, ^req, meta} = Resource.delete(id, req)
      assert path == "/resources/#{id}"

      assert meta == %{
               controller: ResourceController,
               path: "/resources/:id",
               path_params: [id: id]
             }
    end
  end
end

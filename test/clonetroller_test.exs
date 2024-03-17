defmodule ClonetrollerTest do
  use ExUnit.Case, async: true
  doctest Clonetroller

  defmodule Router do
    use Phoenix.Router

    @compile {:no_warn_undefined, ResourceController}

    resources "/resources", ResourceController
  end

  defmodule Resource do
    @behaviour Clonetroller
    import Clonetroller, only: [clone: 2]

    clone Router, ResourceController

    @impl Clonetroller
    def request(verb, path, request, meta) do
      send(self(), {verb, path, request, meta})
    end
  end

  setup do
    [req: %{ref: make_ref()}]
  end

  describe "basic clone" do
    test "index", %{req: req} do
      Resource.index(req)

      assert_received {:get, path, ^req, meta}
      assert path == "/resources"
      assert meta == %{controller: ResourceController, path: "/resources", path_params: []}
    end

    test "new", %{req: req} do
      Resource.new(req)

      assert_received {:get, path, ^req, meta}
      assert path == "/resources/new"
      assert meta == %{controller: ResourceController, path: "/resources/new", path_params: []}
    end

    test "create", %{req: req} do
      Resource.create(req)

      assert_received {:post, path, ^req, meta}
      assert path == "/resources"
      assert meta == %{controller: ResourceController, path: "/resources", path_params: []}
    end

    test "show", %{req: req} do
      id = 3 |> :crypto.strong_rand_bytes() |> Base.url_encode64()

      Resource.show(id, req)

      assert_received {:get, path, ^req, meta}
      assert path == "/resources/#{id}"

      assert meta == %{
               controller: ResourceController,
               path: "/resources/:id",
               path_params: [id: id]
             }
    end

    test "edit", %{req: req} do
      id = 3 |> :crypto.strong_rand_bytes() |> Base.url_encode64()

      Resource.edit(id, req)

      assert_received {:get, path, ^req, meta}
      assert path == "/resources/#{id}/edit"

      assert meta == %{
               controller: ResourceController,
               path: "/resources/:id/edit",
               path_params: [id: id]
             }
    end

    test "update", %{req: req} do
      id = 3 |> :crypto.strong_rand_bytes() |> Base.url_encode64()

      Resource.update(id, req)

      assert_received {:patch, path, ^req, meta}
      assert path == "/resources/#{id}"

      assert meta == %{
               controller: ResourceController,
               path: "/resources/:id",
               path_params: [id: id]
             }
    end

    test "delete", %{req: req} do
      id = 3 |> :crypto.strong_rand_bytes() |> Base.url_encode64()

      Resource.delete(id, req)

      assert_received {:delete, path, ^req, meta}
      assert path == "/resources/#{id}"

      assert meta == %{
               controller: ResourceController,
               path: "/resources/:id",
               path_params: [id: id]
             }
    end
  end
end

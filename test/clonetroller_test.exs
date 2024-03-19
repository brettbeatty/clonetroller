defmodule ClonetrollerTest do
  use ExUnit.Case, async: true
  doctest Clonetroller

  defmodule Router do
    use Phoenix.Router

    @compile {:no_warn_undefined, ResourceController}

    resources "/resources", ResourceController

    scope "/parents/:parent_id" do
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

  defp generate_id, do: 3 |> :crypto.strong_rand_bytes() |> Base.url_encode64()

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
      id = generate_id()

      assert {:get, path, ^req, meta} = Resource.show(id, req)
      assert path == "/resources/#{id}"

      assert meta == %{
               controller: ResourceController,
               path: "/resources/:id",
               path_params: [id: id]
             }
    end

    test "edit", %{req: req} do
      id = generate_id()

      assert {:get, path, ^req, meta} = Resource.edit(id, req)
      assert path == "/resources/#{id}/edit"

      assert meta == %{
               controller: ResourceController,
               path: "/resources/:id/edit",
               path_params: [id: id]
             }
    end

    test "update", %{req: req} do
      id = generate_id()

      assert {:patch, path, ^req, meta} = Resource.update(id, req)
      assert path == "/resources/#{id}"

      assert meta == %{
               controller: ResourceController,
               path: "/resources/:id",
               path_params: [id: id]
             }
    end

    test "delete", %{req: req} do
      id = generate_id()

      assert {:delete, path, ^req, meta} = Resource.delete(id, req)
      assert path == "/resources/#{id}"

      assert meta == %{
               controller: ResourceController,
               path: "/resources/:id",
               path_params: [id: id]
             }
    end
  end

  describe "duplicate routes with additional path params" do
    test "index w/ parent id", %{req: req} do
      parent_id = generate_id()

      assert {:get, path, ^req, meta} = Resource.index(parent_id, req)
      assert path == "/parents/#{parent_id}/resources"

      assert meta == %{
               controller: ResourceController,
               path: "/parents/:parent_id/resources",
               path_params: [parent_id: parent_id]
             }
    end

    test "index w/ query", %{req: req} do
      page_size = :rand.uniform(1_000)
      cursor = generate_id()

      assert {:get, path, ^req, meta} = Resource.index(req, after: cursor, page_size: page_size)
      assert path == "/resources?after=#{cursor}&page_size=#{page_size}"

      assert meta == %{controller: ResourceController, path: "/resources", path_params: []}
    end

    test "index w/ parent id and query", %{req: req} do
      parent_id = generate_id()
      page_size = :rand.uniform(1_000)
      cursor = generate_id()

      assert {:get, path, ^req, meta} =
               Resource.index(parent_id, req, after: cursor, page_size: page_size)

      assert path == "/parents/#{parent_id}/resources?after=#{cursor}&page_size=#{page_size}"

      assert meta == %{
               controller: ResourceController,
               path: "/parents/:parent_id/resources",
               path_params: [parent_id: parent_id]
             }
    end

    test "new w/ parent id", %{req: req} do
      parent_id = generate_id()

      assert {:get, path, ^req, meta} = Resource.new(parent_id, req)
      assert path == "/parents/#{parent_id}/resources/new"

      assert meta == %{
               controller: ResourceController,
               path: "/parents/:parent_id/resources/new",
               path_params: [parent_id: parent_id]
             }
    end

    test "new w/ query", %{req: req} do
      redirect_uri = "https://example.com/#{generate_id()}"

      assert {:get, path, ^req, meta} = Resource.new(req, redirect_uri: redirect_uri)
      assert path == "/resources/new?redirect_uri=#{URI.encode_www_form(redirect_uri)}"
      assert meta == %{controller: ResourceController, path: "/resources/new", path_params: []}
    end

    test "new w/ parent id and query", %{req: req} do
      parent_id = generate_id()
      redirect_uri = "https://example.com/#{generate_id()}"

      assert {:get, path, ^req, meta} = Resource.new(parent_id, req, redirect_uri: redirect_uri)

      assert path ==
               "/parents/#{parent_id}/resources/new?redirect_uri=#{URI.encode_www_form(redirect_uri)}"

      assert meta == %{
               controller: ResourceController,
               path: "/parents/:parent_id/resources/new",
               path_params: [parent_id: parent_id]
             }
    end

    test "create w/ parent_id", %{req: req} do
      parent_id = generate_id()

      assert {:post, path, ^req, meta} = Resource.create(parent_id, req)
      assert path == "/parents/#{parent_id}/resources"

      assert meta == %{
               controller: ResourceController,
               path: "/parents/:parent_id/resources",
               path_params: [parent_id: parent_id]
             }
    end

    test "create w/ query", %{req: req} do
      assert {:post, path, ^req, meta} = Resource.create(req, quiet: true)
      assert path == "/resources?quiet=true"
      assert meta == %{controller: ResourceController, path: "/resources", path_params: []}
    end

    test "create w/ parent_id and query", %{req: req} do
      parent_id = generate_id()

      assert {:post, path, ^req, meta} = Resource.create(parent_id, req, quiet: true)
      assert path == "/parents/#{parent_id}/resources?quiet=true"

      assert meta == %{
               controller: ResourceController,
               path: "/parents/:parent_id/resources",
               path_params: [parent_id: parent_id]
             }
    end

    test "show w/ parent id", %{req: req} do
      parent_id = generate_id()
      id = generate_id()

      assert {:get, path, ^req, meta} = Resource.show(parent_id, id, req)
      assert path == "/parents/#{parent_id}/resources/#{id}"

      assert meta == %{
               controller: ResourceController,
               path: "/parents/:parent_id/resources/:id",
               path_params: [parent_id: parent_id, id: id]
             }
    end

    test "show w/ query", %{req: req} do
      id = generate_id()
      query = [format: :long, show_banner: true]

      assert {:get, path, ^req, meta} = Resource.show(id, req, query)
      assert path == "/resources/#{id}?format=long&show_banner=true"

      assert meta == %{
               controller: ResourceController,
               path: "/resources/:id",
               path_params: [id: id]
             }
    end

    test "show w/ parent id and query", %{req: req} do
      parent_id = generate_id()
      id = generate_id()
      query = [format: :long, show_banner: true]

      assert {:get, path, ^req, meta} = Resource.show(parent_id, id, req, query)
      assert path == "/parents/#{parent_id}/resources/#{id}?format=long&show_banner=true"

      assert meta == %{
               controller: ResourceController,
               path: "/parents/:parent_id/resources/:id",
               path_params: [parent_id: parent_id, id: id]
             }
    end

    test "edit w/ parent id", %{req: req} do
      parent_id = generate_id()
      id = generate_id()

      assert {:get, path, ^req, meta} = Resource.edit(parent_id, id, req)
      assert path == "/parents/#{parent_id}/resources/#{id}/edit"

      assert meta == %{
               controller: ResourceController,
               path: "/parents/:parent_id/resources/:id/edit",
               path_params: [parent_id: parent_id, id: id]
             }
    end

    test "edit w/ query", %{req: req} do
      id = generate_id()
      query = [suggestions: "off"]

      assert {:get, path, ^req, meta} = Resource.edit(id, req, query)
      assert path == "/resources/#{id}/edit?suggestions=off"

      assert meta == %{
               controller: ResourceController,
               path: "/resources/:id/edit",
               path_params: [id: id]
             }
    end

    test "edit w/ parent id and query", %{req: req} do
      parent_id = generate_id()
      id = generate_id()
      query = [suggestions: "off"]

      assert {:get, path, ^req, meta} = Resource.edit(parent_id, id, req, query)
      assert path == "/parents/#{parent_id}/resources/#{id}/edit?suggestions=off"

      assert meta == %{
               controller: ResourceController,
               path: "/parents/:parent_id/resources/:id/edit",
               path_params: [parent_id: parent_id, id: id]
             }
    end

    test "update w/ parent id", %{req: req} do
      parent_id = generate_id()
      id = generate_id()

      assert {:patch, path, ^req, meta} = Resource.update(parent_id, id, req)
      assert path == "/parents/#{parent_id}/resources/#{id}"

      assert meta == %{
               controller: ResourceController,
               path: "/parents/:parent_id/resources/:id",
               path_params: [parent_id: parent_id, id: id]
             }
    end

    test "update w/ query", %{req: req} do
      id = generate_id()

      assert {:patch, path, ^req, meta} = Resource.update(id, req, [])
      assert path == "/resources/#{id}"

      assert meta == %{
               controller: ResourceController,
               path: "/resources/:id",
               path_params: [id: id]
             }
    end

    test "update w/ parent id and query", %{req: req} do
      parent_id = generate_id()
      id = generate_id()

      assert {:patch, path, ^req, meta} = Resource.update(parent_id, id, req, [])
      assert path == "/parents/#{parent_id}/resources/#{id}"

      assert meta == %{
               controller: ResourceController,
               path: "/parents/:parent_id/resources/:id",
               path_params: [parent_id: parent_id, id: id]
             }
    end

    test "delete w/ parent id", %{req: req} do
      parent_id = generate_id()
      id = generate_id()

      assert {:delete, path, ^req, meta} = Resource.delete(parent_id, id, req)
      assert path == "/parents/#{parent_id}/resources/#{id}"

      assert meta == %{
               controller: ResourceController,
               path: "/parents/:parent_id/resources/:id",
               path_params: [parent_id: parent_id, id: id]
             }
    end

    test "delete w/ query", %{req: req} do
      id = generate_id()
      query = [type: :soft, notify: true]

      assert {:delete, path, ^req, meta} = Resource.delete(id, req, query)
      assert path == "/resources/#{id}?type=soft&notify=true"

      assert meta == %{
               controller: ResourceController,
               path: "/resources/:id",
               path_params: [id: id]
             }
    end

    test "delete w/ parent id and query", %{req: req} do
      parent_id = generate_id()
      id = generate_id()
      query = [type: :soft, notify: true]

      assert {:delete, path, ^req, meta} = Resource.delete(parent_id, id, req, query)
      assert path == "/parents/#{parent_id}/resources/#{id}?type=soft&notify=true"

      assert meta == %{
               controller: ResourceController,
               path: "/parents/:parent_id/resources/:id",
               path_params: [parent_id: parent_id, id: id]
             }
    end
  end
end

# Clonetroller
<!-- MODULEDOC -->
Clonetroller clones Phoenix controllers to create clients.

It may not seem terribly useful to have a client module that depends on the Phoenix router to compile, but I ended up wanting this in the contexts of livebooks and tests that call out to other instances of my app.

## Usage
The client module should use the `Clonetroller.clone/2` macro to create functions of the same names as a controller's actions.

```elixir
defmodule MyClient do
  import Clonetroller

  clone MyAppWeb.Router, MyAppWeb.MyController
end
```

This module will also need to implement the `c:Clonetroller.request/4` callback, which the generated functions will call.

```elixir
defmodule MyClient do
  @behaviour Clonetroller
  import Clonetroller

  clone MyAppWeb.Router, MyAppWeb.MyController

  @impl Clonetroller
  def request(:post, path, request, _meta) do
    MyHTTP.post!(path, request)
  end
end
```

The generated functions take arguments for each path parameter, followed by a map representing the request (usually params) and an optional list of query params.

```elixir
MyClient.update("6d5b48e5-f005-4572-912b-22ae1e84a1b5", %{key: "value"}, some: "query param")
#=> PATCH /resources/6d5b48e5-f005-4572-912b-22ae1e84a1b5?some=query+param key=value
```

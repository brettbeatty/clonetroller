defmodule Clonetroller do
  @type controller() :: module()
  @type meta() :: %{controller: controller(), path: path(), path_params: keyword()}
  @type path() :: String.t()
  @type request() :: map()
  @type router() :: module()
  @type verb() :: atom()

  @callback request(verb(), path(), request(), meta()) :: any()

  @typep action() :: atom()
  @typep endpoint() :: %{
           action: action(),
           controller: controller(),
           helper: String.t(),
           path: path(),
           path_params: [String.t()],
           verb: verb()
         }
  @typep variable() :: {atom(), keyword(), atom()}

  defmacro clone(router, controller) do
    router = Macro.expand(router, __CALLER__)
    controller = Macro.expand(controller, __CALLER__)
    build_clone(router, controller)
  end

  @spec build_clone(router(), controller()) :: Macro.t()
  defp build_clone(router, controller) do
    controller
    |> get_endpoints(router)
    |> uniq()
    |> build_functions(router)
  end

  @spec get_endpoints(controller(), router()) :: [endpoint()]
  defp get_endpoints(controller, router) do
    for route = %{plug: ^controller, plug_opts: action} <- router.__routes__(),
        is_atom(action) and not is_nil(route.helper) do
      %{
        action: action,
        controller: controller,
        helper: route.helper,
        path: route.path,
        path_params: parse_path_params(route.path),
        verb: route.verb
      }
    end
  end

  @spec parse_path_params(path()) :: [String.t()]
  defp parse_path_params(path) do
    for ":" <> param <- Path.split(path), do: param
  end

  @spec uniq([endpoint()]) :: [endpoint()]
  defp uniq(endpoints) do
    endpoints
    |> Enum.group_by(&{&1.action, length(&1.path_params)})
    |> Enum.map(fn {_key, group} -> hd(group) end)
  end

  @spec build_functions([endpoint()], router()) :: Macro.t()
  defp build_functions(endpoints, router) do
    quote generated: true do
      (unquote_splicing(
         for endpoint <- endpoints do
           vars = build_vars(endpoint)

           quote generated: true do
             def unquote(endpoint.action)(unquote_splicing(vars), request) do
               request(
                 unquote(endpoint.verb),
                 unquote(router).Helpers.unquote(:"#{endpoint.helper}_path")(
                   %URI{},
                   unquote(endpoint.action),
                   unquote_splicing(vars)
                 ),
                 request,
                 %{
                   controller: unquote(endpoint.controller),
                   path: unquote(endpoint.path),
                   path_params: unquote(Enum.map(vars, &{elem(&1, 0), &1}))
                 }
               )
             end
           end
         end
       ))
    end
  end

  @spec build_vars(endpoint()) :: [variable()]
  defp build_vars(endpoint) do
    for param <- endpoint.path_params do
      param
      |> String.to_atom()
      |> Macro.unique_var(__MODULE__)
    end
  end
end

defmodule Clonetroller do
  @type controller() :: module()
  @type meta() :: %{controller: controller(), path: path(), path_params: keyword()}
  @type path() :: String.t()
  @type request() :: map()
  @type router() :: module()
  @type verb() :: atom()

  @callback request(verb(), path(), request(), meta()) :: any()

  @typep action() :: atom()
  @typep arity_group() ::
           {[atom()], endpoint(), endpoint()}
           | {[atom()], nil, endpoint()}
           | {[atom()], endpoint(), nil}
  @typep endpoint() :: %{
           action: action(),
           controller: controller(),
           helper: String.t(),
           path: path(),
           path_params: [String.t()],
           verb: verb()
         }

  defmacro clone(router, controller) do
    router = Macro.expand(router, __CALLER__)
    controller = Macro.expand(controller, __CALLER__)
    build_clone(router, controller)
  end

  @spec build_clone(router(), controller()) :: Macro.t()
  defp build_clone(router, controller) do
    controller
    |> get_endpoints(router)
    |> build_arity_groups()
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

  @spec build_arity_groups([endpoint()]) :: [arity_group()]
  defp build_arity_groups(endpoints) do
    endpoints
    |> group_by_action_and_arity()
    |> merge_args()
  end

  @spec group_by_action_and_arity([endpoint()]) :: %{
          {action(), arity()} => {endpoint() | nil, endpoint() | nil}
        }
  defp group_by_action_and_arity(endpoints) do
    Enum.reduce(endpoints, %{}, fn endpoint, acc ->
      action = endpoint.action
      arity = length(endpoint.path_params)

      acc
      |> Map.update({action, arity + 1}, {nil, endpoint}, &put_elem(&1, 1, endpoint))
      |> Map.update({action, arity + 2}, {endpoint, nil}, &put_elem(&1, 0, endpoint))
    end)
  end

  @spec merge_args(%{{action(), arity()} => {endpoint() | nil, endpoint() | nil}}) ::
          [arity_group()]
  defp merge_args(groups) do
    Enum.map(groups, fn {{_action, _arity}, {query_endpoint, no_query_endpoint}} ->
      query_args = get_args(query_endpoint, ["request", "query"])
      no_query_args = get_args(no_query_endpoint, ["request"])
      args = [no_query_args, query_args] |> Enum.reject(&is_nil/1) |> Enum.zip_with(&merge_arg/1)
      {args, query_endpoint, no_query_endpoint}
    end)
  end

  @spec get_args(endpoint() | nil, [String.t()]) :: [String.t()] | nil
  defp get_args(endpoint, suffix) do
    if endpoint do
      endpoint.path_params ++ suffix
    end
  end

  @spec merge_arg([String.t()]) :: atom()
  defp merge_arg(names) do
    names
    |> Enum.uniq()
    |> Enum.join("_or_")
    |> String.to_atom()
  end

  @spec build_functions([arity_group()], router()) :: Macro.t()
  defp build_functions(endpoints, router) do
    functions =
      Enum.flat_map(endpoints, fn {vars, query_endpoint, no_query_endpoint} ->
        [
          query_endpoint && build_function(vars, -2, query_endpoint, router),
          no_query_endpoint && build_function(vars, -1, no_query_endpoint, router)
        ]
      end)

    {:__block__, [generated: true], Enum.reject(functions, &is_nil/1)}
  end

  @spec build_function([atom()], -2..-1, endpoint(), router()) :: Macro.t()
  defp build_function(args, request_index, endpoint, router) do
    action = endpoint.action
    helper = :"#{endpoint.helper}_path"
    verb = endpoint.verb

    vars = Enum.map(args, &Macro.var(&1, __MODULE__))
    {request_var, vars_without_request} = List.pop_at(vars, request_index)

    path_params = endpoint.path_params |> Enum.map(&String.to_atom/1) |> Enum.zip(vars)

    path =
      quote generated: true do
        unquote(router).Helpers.unquote(helper)(
          %URI{},
          unquote(action),
          unquote_splicing(vars_without_request)
        )
      end

    meta =
      quote generated: true do
        %{
          controller: unquote(endpoint.controller),
          path: unquote(endpoint.path),
          path_params: unquote(path_params)
        }
      end

    quote generated: true do
      def unquote(action)(unquote_splicing(vars)) when is_map(unquote(request_var)) do
        request(
          unquote(verb),
          unquote(path),
          unquote(request_var),
          unquote(meta)
        )
      end
    end
  end
end

defmodule ExGraph.Utils do
  @moduledoc false

  @base_url "https://graph.microsoft.com/v1.0"

  @type odata_op :: :eq

  @type odata_filter :: {field :: String.t(), op :: odata_op(), value :: String.t()}
  @type odata_query_param ::
          {:select, [String.t()]} | {:top, pos_integer()} | {:filter, odata_filter()}
  @type odata_query :: Enumerable.t(odata_query_param())

  @doc """
  Transform the odata query map with atom keys into a map with string keys and values
  """
  @spec odata_query(query :: odata_query()) :: map()
  def odata_query(query) do
    query
    |> Enum.map(&transform_odata_query_param/1)
    |> Map.new()
  end

  defp transform_odata_query_param({:select, fields}), do: {"$select", Enum.join(fields, ",")}
  defp transform_odata_query_param({:top, top}), do: {"$top", Integer.to_string(top)}
  defp transform_odata_query_param({:filter, filter}), do: {"$filter", transform_odata_filter(filter)}

  defp transform_odata_filter(filter) when is_list(filter), do: Enum.map_join(filter, " and ", &transform_odata_filter/1)

  defp transform_odata_filter({field, :eq, value}) when is_binary(value), do: "#{field} eq '#{value}'"
  defp transform_odata_filter({field, :eq, value}), do: "#{field} eq #{value}"

  @type request_opt :: {:odata, map()} | {:body, map()} | {:query, map()}

  @doc """
  Make an authed request to the Microsoft Graph API
  """
  @spec request(path :: String.t(), method :: Finch.Request.method(), access_token :: String.t(), opts :: [request_opt()]) ::
          {:ok, Finch.Response.t()} | {:error, Finch.Error.t()}
  def request(path, method, access_token, opts \\ []) do
    odata =
      opts
      |> Keyword.get(:odata, %{})
      |> odata_query()

    query =
      opts
      |> Keyword.get(:query, %{})
      |> Map.merge(odata)
      |> URI.encode_query()

    path = "#{path}?#{query}"

    body =
      opts
      |> Keyword.get(:body, %{})
      |> Jason.encode!()

    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Content-Type", "application/json"},
      {"Content-Length", Integer.to_string(byte_size(body))}
    ]

    method
    |> Finch.build(@base_url <> path, headers, body)
    |> Finch.request(finch())
  end

  @doc """
  Make an unauthed request to the Microsoft Graph API
  """
  @spec auth_request(path :: String.t(), method :: Finch.Request.method(), form_params :: Keyword.t()) ::
          {:ok, Finch.Response.t()} | {:error, Finch.Error.t()}
  def auth_request(url, method, form_params) do
    body = URI.encode_query(form_params)

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Content-Length", Integer.to_string(byte_size(body))}
    ]

    method
    |> Finch.build(url, headers, body)
    |> Finch.request(finch())
  end

  @doc """
  Match on request result status and parse body as json if status is ok
  """
  def with_status({:ok, %{status: 401}}, _status), do: {:error, :unauthorized}
  def with_status({:ok, %{status: 403}}, _status), do: {:error, :forbidden}
  def with_status({:ok, %{status: 404}}, _status), do: {:error, :not_found}

  def with_status({:ok, %{status: status, body: ""}}, status), do: {:ok, %{}}
  def with_status({:ok, %{status: status, body: body}}, status), do: {:ok, Jason.decode!(body)}

  def with_status({:ok, %{status: status, body: body}}, _status),
    do: {:error, %{status: status, body: Jason.decode!(body)}}

  def with_status({:error, error}, _status), do: {:error, error}

  defp finch, do: Application.fetch_env!(:ex_microsoft_graph, :finch)
end

defmodule ExGraph.GraphApi do
  @moduledoc """
  The Microsoft API module defining behaviour that has a real implementation and a can
  be mocked for testing
  """

  alias ExGraph.Utils

  @type token :: %{
          refresh_token: String.t(),
          access_token: String.t(),
          expires_at: NaiveDateTime.t()
        }

  @callback authorize_url(client_id :: String.t(), redirect_uri :: String.t(), scopes :: String.t()) :: String.t()
  @callback request_access_token(
              client_id :: String.t(),
              client_secret :: String.t(),
              redirect_uri :: String.t(),
              scopes :: String.t(),
              auth_code :: String.t()
            ) :: {:ok, token()} | {:error, term()}
  @callback refresh_access_token(
              client_id :: String.t(),
              client_secret :: String.t(),
              scopes :: String.t(),
              refresh_token :: String.t()
            ) :: {:ok, token()} | {:error, term()}

  @callback me(access_token :: String.t(), odata :: Utils.odata_query()) :: {:ok, map()} | {:error, term()}

  @callback list_task_lists(access_token :: String.t(), odata :: Utils.odata_query()) :: {:ok, map()} | {:error, term()}
  @callback get_task_list(access_token :: String.t(), id :: String.t()) :: {:ok, map()} | {:error, term()}
  @callback create_task_list(access_token :: String.t(), params :: map()) :: {:ok, map()} | {:error, term()}

  @doc """
  Get the URL to redirect the user to for authorization

  [ref](https://docs.microsoft.com/en-us/graph/auth-v2-user)
  """
  @spec authorize_url(client_id :: String.t(), redirect_uri :: String.t(), scopes :: String.t()) :: String.t()
  def authorize_url(client_id, redirect_uri, scopes) do
    impl().authorize_url(client_id, redirect_uri, scopes)
  end

  @doc """
  Request a new access token using the auth code from the authorization redirect.
  The client_id, redirect_uri, and scopes must match the values used to generate the authorization URL.

  [ref](https://docs.microsoft.com/en-us/graph/auth-v2-user)
  """
  @spec request_access_token(
          client_id :: String.t(),
          client_secret :: String.t(),
          redirect_uri :: String.t(),
          scopes :: String.t(),
          auth_code :: String.t()
        ) :: {:ok, token()} | {:error, term()}
  def request_access_token(client_id, client_secret, redirect_uri, scopes, auth_code) do
    impl().request_access_token(client_id, client_secret, redirect_uri, scopes, auth_code)
  end

  @doc """
  Request a new access token using the refresh token.
  The client_id, and scopes must match the values used to generate the authorization URL.

  [ref](https://docs.microsoft.com/en-us/graph/auth-v2-user)
  """
  @spec refresh_access_token(
          client_id :: String.t(),
          client_secret :: String.t(),
          scopes :: String.t(),
          refresh_token :: String.t()
        ) :: {:ok, token()} | {:error, term()}
  def refresh_access_token(client_id, client_secret, scopes, refresh_token) do
    impl().refresh_access_token(client_id, client_secret, scopes, refresh_token)
  end

  @doc """
  Get the current user's profile. Optionally selecting a subset of fields

  [ref](https://docs.microsoft.com/en-us/graph/api/user-get)
  """
  @spec me(access_token :: String.t(), odata :: Utils.odata_query()) :: {:ok, map()} | {:error, term()}
  def me(access_token, odata \\ %{}) do
    impl().me(access_token, odata)
  end

  @doc """
  Get the current user's task lists. Optionally selecting a subset of fields

  [ref](https://learn.microsoft.com/en-us/graph/api/todo-list-lists)
  """
  @spec list_task_lists(access_token :: String.t(), odata :: Utils.odata_query()) :: {:ok, map()} | {:error, term()}
  def list_task_lists(access_token, odata \\ %{}) do
    impl().list_task_lists(access_token, odata)
  end

  @doc """
  Get a task list by id

  [ref](https://learn.microsoft.com/en-us/graph/api/todotasklist-get)
  """
  @spec get_task_list(access_token :: String.t(), id :: String.t()) :: {:ok, map()} | {:error, term()}
  def get_task_list(access_token, id) do
    impl().get_task_list(access_token, id)
  end

  @doc """
  Create a task list

  [ref](https://learn.microsoft.com/en-us/graph/api/todo-post-lists)
  """
  @spec create_task_list(access_token :: String.t(), params :: map()) :: {:ok, map()} | {:error, term()}
  def create_task_list(access_token, params) do
    impl().create_task_list(access_token, params)
  end

  defp impl, do: Application.get_env(:ex_microsoft_graph, :graph_api_impl, ExGraph.GraphImpl)
end

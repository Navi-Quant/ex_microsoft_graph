defmodule ExGraph.GraphImpl do
  @moduledoc """
  Implementation of `ExGraph.GraphApi` behaviour
  """

  @behaviour ExGraph.GraphApi

  import ExGraph.Utils

  @authorize_url "https://login.microsoftonline.com/common/oauth2/v2.0/authorize"
  @token_url "https://login.microsoftonline.com/common/oauth2/v2.0/token"

  @impl true
  def authorize_url(client_id, redirect_uri, scopes) do
    params =
      URI.encode_query(
        client_id: client_id,
        response_type: "code",
        redirect_uri: redirect_uri,
        scope: scopes,
        response_mode: "query"
      )

    @authorize_url
    |> URI.new!()
    |> URI.append_query(params)
    |> URI.to_string()
  end

  @impl true
  def request_access_token(client_id, client_secret, redirect_uri, scopes, auth_code) do
    @token_url
    |> auth_request(:post,
      client_id: client_id,
      grant_type: "authorization_code",
      scopes: scopes,
      code: auth_code,
      redirect_uri: redirect_uri,
      client_secret: client_secret
    )
    |> with_status(200)
    |> parse_token_response()
  end

  @impl true
  def refresh_access_token(client_id, client_secret, scopes, refresh_token) do
    @token_url
    |> auth_request(:post,
      client_id: client_id,
      grant_type: "refresh_token",
      scopes: scopes,
      refresh_token: refresh_token,
      client_secret: client_secret
    )
    |> with_status(200)
    |> parse_token_response()
  end

  defp parse_token_response({:ok, %{"access_token" => access, "refresh_token" => refresh, "expires_in" => expires_in}}) do
    expires_at = DateTime.add(DateTime.utc_now(), expires_in, :second)
    {:ok, %{access_token: access, refresh_token: refresh, expires_at: expires_at}}
  end

  defp parse_token_response(res), do: res

  @impl true
  def list_task_lists(access_token, odata) do
    "/me/todo/lists"
    |> request(:get, access_token, odata: odata)
    |> with_status(200)
  end

  @impl true
  def get_task_list(access_token, id) do
    "/me/todo/lists/#{id}"
    |> request(:get, access_token)
    |> with_status(200)
  end

  @impl true
  def create_task_list(access_token, params) do
    "/me/todo/lists"
    |> request(:post, access_token, body: params)
    |> with_status(201)
  end

  @impl true
  def me(access_token, odata) do
    "/me"
    |> request(:get, access_token, odata: odata)
    |> with_status(200)
  end
end

defmodule ExGraphTest do
  use ExUnit.Case

  alias ExGraph.GraphApi
  alias ExGraph.Utils

  describe "authorization" do
    test "authorize_url/3 returns the correct url" do
      client_id = "123"
      redirect_uri = "http://localhost:4000/auth/callback"
      scopes = "User.Read"

      expected =
        "https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=123&response_type=code&redirect_uri=http%3A%2F%2Flocalhost%3A4000%2Fauth%2Fcallback&scope=User.Read&response_mode=query"

      assert GraphApi.authorize_url(client_id, redirect_uri, scopes) == expected
    end
  end

  describe "utils" do
    test "odata_query/1 transforms map to odata query params" do
      query = %{
        select: ["id", "displayName"],
        top: 10,
        filter: [
          {"id", :eq, "123"},
          {"displayName", :eq, "John Doe"}
        ]
      }

      expected = %{
        "$select" => "id,displayName",
        "$top" => "10",
        "$filter" => "id eq '123' and displayName eq 'John Doe'"
      }

      assert Utils.odata_query(query) == expected
    end
  end
end

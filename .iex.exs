{:ok, finch} = Finch.start_link(name: DevFinch)
Application.put_env(:ex_microsoft_graph, :finch, DevFinch)

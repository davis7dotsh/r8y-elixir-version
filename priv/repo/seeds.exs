# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     R8yV4.Repo.insert!(%R8yV4.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias R8yV4.Monitoring

channels = [
  %{
    yt_channel_id: "UCbRP3c757lWg9M-U7TyEkXA",
    name: "Theo (t3.gg)",
    find_sponsor_prompt:
      "The sponsor key for this channel is `https://soydev.link/${SPONSOR_NAME}`. There are often multiple soydev links in the description. The one for the sponsor will come after something similar to 'Thank you ${SPONSOR_NAME} for sponsoring!'. If it doesn't mention that the sponsor name is a sponsor, then there is no sponsor and you should set the sponsor name to 'no sponsor' and the sponsor key to 'https://t3.gg'"
  },
  %{
    yt_channel_id: "UCFvPgPdb_emE_bpMZq6hmJQ",
    name: "Ben Davis",
    find_sponsor_prompt:
      "The sponsor key for this channel is `https://davis7.link/${SPONSOR_NAME}`. There are often multiple davis7 links in the description. The one for the sponsor will come after something similar to 'Thank you ${SPONSOR_NAME} for sponsoring!'. If it doesn't mention that the sponsor name is a sponsor, then there is no sponsor and you should set the sponsor name to 'no sponsor' and the sponsor key to 'https://davis7.link'"
  }
]

for channel <- channels do
  case Monitoring.create_channel(channel) do
    {:ok, created} ->
      IO.puts("Created channel: #{created.name} (#{created.yt_channel_id})")

    {:error, changeset} ->
      IO.puts("Failed to create channel #{channel.name}: #{inspect(changeset.errors)}")
  end
end

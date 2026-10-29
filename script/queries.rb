provider = Provider.find_by!(email: "ada@example.com")
client = Client.find_by!(email: "cam@example.com")

# all clients for a given provider
pp provider.clients.pluck(:name)
# all providers for a given client
pp client.providers.pluck(:name)

# all journal entries for a given client, sorted by date
pp client.journal_entries.chronological(:desc).pluck(:body)

# all journal entries across all clients of a given provider, sorted by date
pp provider.journal_entries.chronological(:desc).pluck(:body)

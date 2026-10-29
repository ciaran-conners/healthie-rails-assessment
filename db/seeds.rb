# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
ada = Provider.find_or_create_by!(email: "ada@example.com") { |p| p.name = "Dr. Ada" }
bo  = Provider.find_or_create_by!(email: "bo@example.com")  { |p| p.name = "Dr. Bo" }

cam = Client.find_or_create_by!(email: "cam@example.com") { |c| c.name = "Cam" }
dee = Client.find_or_create_by!(email: "dee@example.com") { |c| c.name = "Dee" }

Subscription.find_or_create_by!(provider: ada, client: cam) { |s| s.plan = "premium" }
Subscription.find_or_create_by!(provider: bo,  client: cam) { |s| s.plan = "basic" }
Subscription.find_or_create_by!(provider: ada, client: dee) { |s| s.plan = "basic" }

if JournalEntry.none?
  cam.journal_entries.create!(body: "Ate oatmeal", created_at: 2.days.ago)
  dee.journal_entries.create!(body: "Went for a run", created_at: 1.day.ago)
  cam.journal_entries.create!(body: "Skipped lunch")
end

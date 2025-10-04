json.array!(@authors) do |author|
  json.extract! author, :id, :name, :year_of_birth, :year_of_death, :where, :about
  json.url author_url(author, format: :json)
end

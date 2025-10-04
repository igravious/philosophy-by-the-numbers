json.array!(@dictionaries) do |dictionary|
  json.extract! dictionary, :id, :title, :long_title, :URI, :current_editor, :contact, :organisation
  json.url dictionary_url(dictionary, format: :json)
end

json.array!(@names) do |name|
  json.extract! name, :id, :shadow_id, :label, :lang
  json.url name_url(name, format: :json)
end

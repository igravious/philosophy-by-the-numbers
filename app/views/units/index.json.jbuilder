json.array!(@units) do |unit|
  json.extract! unit, :id, :dictionary_id, :entry
  json.url unit_url(unit, format: :json)
end

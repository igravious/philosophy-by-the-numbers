json.array!(@filters) do |filter|
  json.extract! filter, :id, :name, :tag_id, :inequality, :original_year
  json.url filter_url(filter, format: :json)
end

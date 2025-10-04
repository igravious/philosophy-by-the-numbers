json.array!(@resources) do |resource|
  json.extract! resource, :id, :URI
  json.url resource_url(resource, format: :json)
end

json.array!(@links) do |link|
  json.extract! link, :id, :table_name, :row_id, :IRI, :description
  json.url link_url(link, format: :json)
end

json.array!(@labelings) do |labeling|
  json.extract! labeling, :id, :tag_id, :text_id
  json.url labeling_url(labeling, format: :json)
end

json.array!(@writings) do |writing|
  json.extract! writing, :id, :author_id, :text_id
  json.url writing_url(writing, format: :json)
end

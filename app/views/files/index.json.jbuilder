json.array!(@files) do |file|
  json.extract! file, :id, :URL, :what
  json.url file_url(file, format: :json)
end

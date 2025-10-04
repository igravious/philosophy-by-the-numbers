class CreateHttpRequestLoggers < ActiveRecord::Migration
  def change
    create_table :http_request_loggers do |t|
      t.string :caller
      t.string :uri
      t.string :request
      t.text :response

      t.timestamps
    end
  end
end

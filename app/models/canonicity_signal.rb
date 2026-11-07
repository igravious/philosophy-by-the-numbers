class CanonicitySignal < ActiveRecord::Base
  validates :algorithm_version, :name, :source, presence: true
  validates :name, uniqueness: {scope: :algorithm_version}
end

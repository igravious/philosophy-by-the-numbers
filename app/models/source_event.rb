class SourceEvent < ActiveRecord::Base
  serialize :old_value, JSON
  serialize :new_value, JSON
  serialize :provenance, JSON

  belongs_to :shadow

  validates :source_name, :import_identity, :artifact_identity, :artifact_checksum, presence: true
  validates :shadow_id, :shadow_type, :entity_id, :attribute_name, :imported_at, presence: true
  validates :provenance, exclusion: {in: [nil]}
  validates :shadow_type, inclusion: {in: %w[Philosopher Work]}
end

# frozen_string_literal: true

require "json"

module ZoteroSingletonIds
  module_function

  # Loads and validates a singleton ID registry.
  #
  # @param path [String] registry path
  # @return [Array<Hash>] key-sorted +key+ and +id+ records; empty when absent
  # @raise [RuntimeError] for malformed records or duplicate keys/IDs
  def load(path)
    return [] unless File.exist?(path)

    records = JSON.parse(File.read(path))
    raise "singleton ID registry must be an array" unless records.is_a?(Array)

    records = records.map do |record|
      unless record.is_a?(Hash) && record.keys.sort == %w[id key] &&
          record["key"].is_a?(String) && !record["key"].empty? && record["id"].is_a?(String) && record["id"].match?(/\AEP-\d{3,}\z/)
        raise "invalid singleton ID record: #{record.inspect}"
      end
      record
    end
    duplicate_keys = duplicates(records.map { |record| record["key"] })
    duplicate_ids = duplicates(records.map { |record| record["id"] })
    raise "duplicate singleton keys: #{duplicate_keys.join(", ")}" unless duplicate_keys.empty?
    raise "duplicate singleton EP IDs: #{duplicate_ids.join(", ")}" unless duplicate_ids.empty?

    records.sort_by { |record| record["key"] }
  end

  # Adds mappings for new singletons without changing or removing existing ones.
  #
  # @param path [String] registry path
  # @param current_keys [Array<String>] current singleton keys in allocation order
  # @param reserved_ids [Array<String>] every active, retired, or logged EP ID
  # @param allowed_ids [Array<String>] reserved IDs preserved by same-record transitions
  # @param persist [Boolean] whether to write additions immediately
  # @return [Hash<String, String>] all active and dormant key-to-ID mappings
  # @raise [RuntimeError] when a stored ID collides with a reserved ID
  def reconcile(path, current_keys, reserved_ids, allowed_ids: [], persist: true)
    records = load(path)
    collisions = records.map { |record| record["id"] } & (reserved_ids - allowed_ids)
    raise "singleton EP IDs collide with previously assigned IDs: #{collisions.join(", ")}" unless collisions.empty?

    known = records.each_with_object({}) { |record, by_key| by_key[record["key"]] = record["id"] }
    next_number = (reserved_ids + known.values).map { |id| id[/\AEP-(\d{3,})\z/, 1] }.compact.map(&:to_i).max.to_i + 1
    changed = false
    current_keys.each do |key|
      next if known.key?(key)

      id = format("EP-%03d", next_number)
      next_number += 1
      record = {"key" => key, "id" => id}
      records << record
      known[key] = id
      changed = true
    end
    write(path, records) if changed && persist
    known
  end

  # Writes a registry in deterministic key order.
  #
  # @param path [String] registry path
  # @param records [Array<Hash>] +key+ and +id+ records
  # @return [Integer] number of bytes written
  def write(path, records)
    File.write(path, JSON.pretty_generate(records.sort_by { |record| record["key"] }) + "\n")
  end

  # Finds duplicate values in an enumerable.
  #
  # @param values [Enumerable] values to inspect
  # @return [Array] values occurring more than once
  def duplicates(values)
    values.group_by(&:itself).select { |_, occurrences| occurrences.size > 1 }.keys
  end
end

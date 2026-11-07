require "test_helper"
require "minitest/mock"

class CanonicityDankerImportTest < ActiveSupport::TestCase
  def with_file(contents)
    file = Tempfile.new(["danker", ".csv"], Rails.root.join("tmp").to_s)
    file.write(contents)
    file.close
    yield file.path
  ensure
    file&.unlink
  end

  test "imports scores atomically with source events and nil for missing entities" do
    included = create_test_philosopher(entity_id: 42, danker: 0.5)
    missing = create_test_philosopher(entity_id: 43, danker: 0.25)

    with_file("Q42,0.75\n") do |path|
      Canonicity::DankerImport.new(path, subject_type: "Philosopher").call
    end

    assert_equal 0.75, included.reload.danker
    assert_nil missing.reload.danker
    included_event = SourceEvent.find_by!(shadow_id: included.id, attribute_name: "danker")
    missing_event = SourceEvent.find_by!(shadow_id: missing.id, attribute_name: "danker")
    assert_equal 0.5, included_event.old_value
    assert_equal 0.75, included_event.new_value
    assert_equal 0.25, missing_event.old_value
    assert_nil missing_event.new_value
    assert_equal included_event.import_identity, missing_event.import_identity
  end

  test "rejects the whole file before changing inputs or events" do
    philosopher = create_test_philosopher(entity_id: 42, danker: 0.5)

    with_file("Q42,0.75\nnot-a-score\n") do |path|
      assert_raises(Canonicity::ImportError) do
        Canonicity::DankerImport.new(path, subject_type: "Philosopher").call
      end
    end

    assert_equal 0.5, philosopher.reload.danker
    assert_equal 0, SourceEvent.count
  end

  test "validation retains only scores needed by the subject population" do
    create_test_philosopher(entity_id: 42)

    with_file("Q42,0.75\nQ999999,0.25\n") do |path|
      importer = Canonicity::DankerImport.new(path, subject_type: "Philosopher")
      assert_equal({42 => 0.75}, importer.send(:validated_scores))
      assert_equal(Digest::SHA256.hexdigest("Q42,0.75\nQ999999,0.25\n"), importer.send(:artifact_checksum))
    end
  end

  test "import does not reread the artifact for its checksum inside the transaction" do
    create_test_philosopher(entity_id: 42)

    with_file("Q42,0.75\n") do |path|
      importer = Canonicity::DankerImport.new(path, subject_type: "Philosopher")
      Digest::SHA256.stub(:file, ->(*) { raise "artifact was reread" }) { importer.call }
    end

    assert_equal 0.75, Philosopher.find_by(entity_id: 42).danker
  end
end

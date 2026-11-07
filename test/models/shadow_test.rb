require 'test_helper'

class ShadowTest < ActiveSupport::TestCase
  test "philosopher has canonicity measurement fields" do
    philosopher = Philosopher.new
    assert_respond_to philosopher, :measure
    assert_respond_to philosopher, :measure_pos
    assert_respond_to philosopher, :danker
    assert_respond_to philosopher, :mention
    assert_respond_to philosopher, :linkcount
  end

  test "philosopher has source presence fields" do
    philosopher = Philosopher.new
    assert_respond_to philosopher, :oxford2
    assert_respond_to philosopher, :oxford3
    assert_respond_to philosopher, :stanford
    assert_respond_to philosopher, :routledge
    assert_respond_to philosopher, :cambridge
    assert_respond_to philosopher, :borchert
    assert_respond_to philosopher, :internet
    assert_respond_to philosopher, :kemerling
    assert_respond_to philosopher, :inphobool
    assert_respond_to philosopher, :dbpedia
    assert_respond_to philosopher, :populate
  end

  test "has_many names association" do
    phil = create_test_philosopher
    Name.create!(shadow_id: phil.id, lang: 'en', label: 'Socrates')
    Name.create!(shadow_id: phil.id, lang: 'de', label: 'Sokrates')
    assert_equal 2, phil.names.count
  end

  test "names association with dependent destroy" do
    phil = create_test_philosopher
    Name.create!(shadow_id: phil.id, lang: 'en', label: 'Test Philosopher')
    assert_equal 1, Name.where(shadow_id: phil.id).count
    phil.destroy
    assert_equal 0, Name.where(shadow_id: phil.id).count
  end

  test "column_direction returns asc for entity_id and label" do
    assert_equal 'asc', Shadow.column_direction('entity_id')
    assert_equal 'asc', Shadow.column_direction('label')
  end

  test "column_direction returns desc for other columns" do
    assert_equal 'desc', Shadow.column_direction('mention')
    assert_equal 'desc', Shadow.column_direction('measure')
    assert_equal 'desc', Shadow.column_direction('danker')
  end

  test "get_year parses date string from shadows column" do
    phil = create_test_philosopher
    phil.update_column(:date_hack, '1724-04-22')
    phil.reload
    assert_equal 1724, phil.get_year(:date_hack)
  end

  test "get_year returns nil for blank column" do
    phil = create_test_philosopher
    assert_nil phil.get_year(:date_hack)
  end

  test "get_year parses delegated birth dates" do
    phil = create_test_philosopher(birth: '1724-04-22')
    assert_equal 1724, phil.get_year(:birth)
  end

  test "year parses approximate delegated dates" do
    phil = create_test_philosopher(birth: '-470', birth_approx: true)
    assert_equal(-470, phil.year(:birth))
  end

  test "year returns nil for blank column" do
    phil = create_test_philosopher
    assert_nil phil.year(:date_hack)
  end

  test "year handles non-approx date on shadows column" do
    phil = create_test_philosopher
    phil.update_column(:date_hack, '1844-10-15;extra')
    phil.reload
    assert_equal 1844, phil.year(:date_hack)
  end

  test "year returns nil on parse error" do
    phil = create_test_philosopher
    phil.update_column(:date_hack, 'not-a-date')
    phil.reload
    assert_nil phil.year(:date_hack)
  end

  test "english returns label for en name" do
    phil = create_test_philosopher
    Name.create!(shadow_id: phil.id, lang: 'en', label: 'Immanuel Kant')
    assert_equal 'Immanuel Kant', phil.english
  end

  test "english returns empty string when no en name exists" do
    phil = create_test_philosopher
    assert_equal '', phil.english
  end

  test "english returns empty string when only non-en names exist" do
    phil = create_test_philosopher
    Name.create!(shadow_id: phil.id, lang: 'de', label: 'Sokrates')
    assert_equal '', phil.english
  end

  test "do_q is a no-op method" do
    phil = create_test_philosopher
    assert_nil phil.do_q(:anything)
  end
end

class PhilosopherTest < ActiveSupport::TestCase
  setup do
    @philosopher = Philosopher.new(
      entity_id: 1234,
      mention: 100,
      danker: 0.5,
      oxford2: false,
      oxford3: true,
      stanford: true,
      routledge: false,
      cambridge: true,
      borchert: true,
      internet: false,
      kemerling: false,
      inphobool: true,
      dbpedia: true,
      populate: true
    )
  end

  test "philosopher responds to canonicity methods" do
    assert_respond_to @philosopher, :capacities
    assert_respond_to @philosopher, :relevant?
    assert_respond_to @philosopher, :birth_death
  end

  test "philosopher canonicity calculation inputs are preserved" do
    @philosopher.save!

    saved_philosopher = Philosopher.find(@philosopher.id)
    assert_equal 100, saved_philosopher.mention
    assert_equal 0.5, saved_philosopher.danker
    assert_not saved_philosopher.oxford2
    assert saved_philosopher.oxford3
    assert saved_philosopher.stanford
    assert_not saved_philosopher.routledge
    assert saved_philosopher.cambridge
  end

  test "has_one attrs association auto-builds" do
    phil = Philosopher.new(entity_id: 50001)
    assert_not_nil phil.attrs
    assert_instance_of PhilosopherAttrs, phil.attrs
  end

  test "attrs are created on save" do
    phil = Philosopher.new(entity_id: 50002)
    phil.save!
    assert_not_nil PhilosopherAttrs.find_by(shadow_id: phil.id)
  end

  test "delegated attributes write through to attrs" do
    phil = create_test_philosopher(birth: '1724-04-22', birth_approx: false, gender: 'male')
    phil.reload
    assert_equal '1724-04-22', phil.birth
    assert_equal false, phil.birth_approx
    assert_equal 'male', phil.gender
  end

  test "delegated boolean flags persist correctly" do
    phil = create_test_philosopher(
      stanford: true, oxford2: false, dbpedia: true,
      internet: false, kemerling: true, runes: false,
      inphobool: true, populate: false
    )
    phil.reload
    assert phil.stanford
    assert_not phil.oxford2
    assert phil.dbpedia
    assert_not phil.internet
    assert phil.kemerling
    assert_not phil.runes
    assert phil.inphobool
    assert_not phil.populate
  end

  test "initialize handles mass assignment of delegated attributes" do
    phil = Philosopher.new(
      entity_id: 50003,
      birth: '1844-10-15',
      death: '1900-08-25',
      stanford: true
    )
    assert_equal '1844-10-15', phil.birth
    assert_equal '1900-08-25', phil.death
    assert phil.stanford
  end

  test "has_many metric_snapshots scoped to Philosopher" do
    phil = create_test_philosopher
    assert_respond_to phil, :metric_snapshots
  end

  test "has_many works through expressions" do
    phil = create_test_philosopher
    work = create_test_work
    Expression.create!(creator_id: phil.id, work_id: work.id)
    assert_includes phil.works, work
  end

  test "has_many creations through route_a" do
    phil = create_test_philosopher
    work = create_test_work
    Expression.create!(creator_id: phil.id, work_id: work.id)
    assert_includes phil.creations, work
  end

  test "join_attribute returns creator_id hash" do
    phil = create_test_philosopher
    assert_equal({ creator_id: phil.id }, phil.join_attribute)
  end

  test "reference_work_flags_json returns valid JSON" do
    phil = create_test_philosopher(
      stanford: true, oxford2: false, dbpedia: true,
      internet: false, kemerling: false, runes: false,
      inphobool: true, populate: false
    )
    json = JSON.parse(phil.reference_work_flags_json)
    assert_equal true, json['stanford']
    assert_equal false, json['oxford2']
    assert_equal true, json['dbpedia']
    assert_equal true, json['inphobool']
    assert_equal false, json['runes']
  end

  test "reference_work_flags_json defaults nil to false" do
    phil = create_test_philosopher
    json = JSON.parse(phil.reference_work_flags_json)
    json.each do |key, value|
      assert_equal false, value, "Expected #{key} to be false, got #{value}"
    end
  end

  test "birth_death renders delegated dates" do
    phil = create_test_philosopher(birth: '1724', birth_approx: true, death: '1804', death_approx: true)
    assert_equal '(1724–1804)', phil.birth_death
  end

  test "birth_death handles both nil" do
    phil = create_test_philosopher(birth: nil, death: nil)
    assert_equal '(0)', phil.birth_death
  end

  test "capacities returns capacities via roles" do
    phil = create_test_philosopher
    assert_respond_to phil, :capacities
    assert_equal 0, phil.capacities.count
  end

  test "relevant? returns false when no capacities" do
    phil = create_test_philosopher
    assert_not phil.relevant?
  end

  test "phil_null scope" do
    assert_respond_to Philosopher, :phil_null
    result = Philosopher.phil_null
    assert_kind_of ActiveRecord::Relation, result
  end

  test "repo scope filters unreferenced philosophers" do
    assert_respond_to Philosopher, :repo
    result = Philosopher.repo
    assert_kind_of ActiveRecord::Relation, result
  end

  # show_label with lang='all' and individual=true uses Name model (not self.label)
  test "show_label with all language and individual true" do
    phil = create_test_philosopher
    Name.create!(shadow_id: phil.id, lang: 'en', label: 'Socrates', langorder: 10)
    w_label, w_lang, en_label, label = phil.show_label('all', true)
    assert_equal 'Socrates', w_label
    assert_equal 'en', w_lang
    assert_equal 'Socrates', en_label
  end

  test "show_label with all language and no names falls back to entity_id" do
    phil = create_test_philosopher
    w_label, w_lang, en_label, label = phil.show_label('all', true)
    assert_match(/Q#{phil.entity_id}/, label)
    assert_equal '*', w_lang
  end

  # show_label with specific language or all/false uses self.label/self.lang
  # which only exist when loaded via join with names table — can't test in isolation
end

class WorkTest < ActiveSupport::TestCase
  test "has_one attrs association auto-builds" do
    work = Work.new(entity_id: 60001)
    assert_not_nil work.attrs
    assert_instance_of WorkAttrs, work.attrs
  end

  test "attrs are created on save" do
    work = Work.new(entity_id: 60002)
    work.save!
    assert_not_nil WorkAttrs.find_by(shadow_id: work.id)
  end

  # work_attrs column types: pub=string, pub_approx=string (not boolean!),
  # genre=boolean, obsolete=boolean, philrecord=string, philtopic=string,
  # britannica=string, image=string, philosophical=integer
  test "delegated string attributes write through to attrs" do
    work = create_test_work(pub: '1781', work_lang: 'de')
    work.reload
    assert_equal '1781', work.pub
    assert_equal 'de', work.work_lang
  end

  test "delegated boolean genre persists correctly" do
    work = create_test_work(genre: true)
    work.reload
    assert work.genre
  end

  test "initialize handles mass assignment of delegated attributes" do
    work = Work.new(
      entity_id: 60003,
      pub: '1781',
      work_lang: 'de',
      genre: true
    )
    assert_equal '1781', work.pub
    assert_equal 'de', work.work_lang
    assert work.genre
  end

  test "delegated boolean flags persist correctly" do
    work = create_test_work(genre: true, obsolete: false)
    work.reload
    assert work.genre
    assert_not work.obsolete
  end

  # philrecord, philtopic, britannica are STRING columns (not boolean).
  # SQLite stores true as 't' for string columns.
  test "string-typed flag columns store truthy values" do
    work = create_test_work(philrecord: 'yes', philtopic: 'yes')
    work.reload
    assert_not_nil work.philrecord
    assert_not_nil work.philtopic
  end

  test "has_many creators through expressions" do
    phil = create_test_philosopher
    work = create_test_work
    Expression.create!(creator_id: phil.id, work_id: work.id)
    assert_includes work.creators, phil
  end

  test "join_attribute returns work_id hash" do
    work = create_test_work
    assert_equal({ work_id: work.id }, work.join_attribute)
  end

  test "reference_work_flags_json returns valid JSON with all keys" do
    work = create_test_work
    json = JSON.parse(work.reference_work_flags_json)
    %w[borchert cambridge routledge philrecord philtopic].each do |key|
      assert json.key?(key), "Missing key: #{key}"
    end
  end

  test "reference_work_flags_json defaults nil to false" do
    work = create_test_work
    json = JSON.parse(work.reference_work_flags_json)
    assert_equal false, json['borchert']
  end

  test "has_many metric_snapshots scoped to Work" do
    work = create_test_work
    assert_respond_to work, :metric_snapshots
  end

  test "english returns label for en name" do
    work = create_test_work
    Name.create!(shadow_id: work.id, lang: 'en', label: 'Critique of Pure Reason')
    assert_equal 'Critique of Pure Reason', work.english
  end

  test "english returns empty string when no en name exists" do
    work = create_test_work
    assert_equal '', work.english
  end

  test "year parses delegated publication dates" do
    work = create_test_work(pub: '1781', pub_approx: true)
    assert_equal 1781, work.year(:pub)
  end

  test "Work and Philosopher are distinct STI subclasses" do
    phil = create_test_philosopher
    work = create_test_work
    assert_equal 'Philosopher', phil.class.name
    assert_equal 'Work', work.class.name
    assert_equal 'Philosopher', Philosopher.find(phil.id).class.name
    assert_equal 'Work', Work.find(work.id).class.name
  end

  test "Work DELEGATED_ATTRIBUTES includes expected fields" do
    expected = %w[pub pub_year pub_approx work_lang copyright genre obsolete
                  philrecord philtopic britannica image philosophical]
    expected.each do |attr|
      assert_includes Work::DELEGATED_ATTRIBUTES, attr, "Missing delegated attribute: #{attr}"
    end
  end

  test "Philosopher DELEGATED_ATTRIBUTES includes expected fields" do
    expected = %w[birth birth_approx birth_year death death_approx death_year
                  floruit period dbpedia oxford2 oxford3 stanford internet
                  kemerling runes populate inpho inphobool gender philosopher]
    expected.each do |attr|
      assert_includes Philosopher::DELEGATED_ATTRIBUTES, attr, "Missing delegated attribute: #{attr}"
    end
  end
end

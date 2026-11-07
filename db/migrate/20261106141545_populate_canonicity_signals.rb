class PopulateCanonicitySignals < ActiveRecord::Migration
  PHILOSOPHER_SIGNALS = [
    ["mention", "Corpus cross-references", "Citation or reference frequency", true, true, true],
    ["danker", "Wikipedia PageRank", "Time-varying web authority score", true, true, true],
    ["linkcount", "Wikipedia links", "Available time-varying link count, unused by V2", true, false, true],
    ["capacities", "Wikidata roles", "Capacity IDs used by the role-suppression rule", true, true, true],
    ["inphobool", "Internet Encyclopedia of Philosophy", "IEP coverage", true, true, true],
    ["borchert", "Macmillan Encyclopedia", "Borchert encyclopedia coverage", true, true, true],
    ["internet", "Internet sources", "Internet-source coverage", true, true, true],
    ["cambridge", "Cambridge Dictionary of Philosophy", "Cambridge coverage", true, true, true],
    ["kemerling", "Kemerling Philosophy Pages", "Kemerling coverage", true, true, true],
    ["populate", "Wikidata", "Philosopher population flag", true, true, true],
    ["oxford2", "Oxford Dictionary of Philosophy, 2nd ed.", "Inactive legacy coverage", true, false, false],
    ["oxford3", "Oxford Dictionary of Philosophy, 3rd ed.", "Oxford third-edition coverage", true, true, true],
    ["routledge", "Routledge Encyclopedia of Philosophy", "Routledge coverage", true, true, true],
    ["dbpedia", "DBpedia", "DBpedia philosopher flag", true, true, true],
    ["stanford", "Stanford Encyclopedia of Philosophy", "SEP coverage", true, true, true],
    ["runes", "Philosophy Dictionary (Runes)", "Inactive legacy coverage", true, false, false]
  ].freeze

  WORK_SIGNALS = [
    ["mention", "Corpus cross-references", "Citation or reference frequency", true, true, true],
    ["danker", "Wikipedia PageRank", "Time-varying web authority score", true, true, true],
    ["linkcount", "Wikipedia links", "Available time-varying link count, unused by V2", true, false, true],
    ["borchert", "Macmillan Encyclopedia", "Borchert encyclopedia coverage", true, true, true],
    ["cambridge", "Cambridge Dictionary of Philosophy", "Cambridge coverage", true, true, true],
    ["routledge", "Routledge Encyclopedia of Philosophy", "Routledge coverage", true, true, true],
    ["philrecord", "PhilPapers", "PhilPapers record identifier", true, true, true],
    ["philtopic", "PhilPapers", "PhilPapers topic identifier", true, true, true],
    ["genre", "Corpus work metadata", "Philosophical versus other genre multiplier", true, true, true],
    ["author_measures", "Completed Philosopher metric run", "Frozen linked-author measures", true, true, true]
  ].freeze

  def up
    insert_signals("2.0", PHILOSOPHER_SIGNALS)
    insert_signals("2.0-work", WORK_SIGNALS)
  end

  def down
    CanonicitySignal.where(algorithm_version: ["2.0", "2.0-work"]).destroy_all
  end

  private

  def insert_signals(version, signals)
    signals.each do |name, source, description, subject_to_change, used_in_formula, active|
      CanonicitySignal.create!(
        algorithm_version: version,
        name: name,
        source: source,
        description: description,
        subject_to_change: subject_to_change,
        used_in_formula: used_in_formula,
        active: active
      )
    end
  end
end

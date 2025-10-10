class RemoveMigratedColumnsFromShadows < ActiveRecord::Migration
  def up
    # Remove Philosopher-only columns (17 columns)
    remove_column :shadows, :birth, :string
    remove_column :shadows, :birth_approx, :boolean
    remove_column :shadows, :birth_year, :integer
    remove_column :shadows, :death, :string
    remove_column :shadows, :death_approx, :boolean
    remove_column :shadows, :death_year, :integer
    remove_column :shadows, :floruit, :string
    remove_column :shadows, :period, :string
    remove_column :shadows, :dbpedia, :boolean
    remove_column :shadows, :oxford2, :boolean
    remove_column :shadows, :oxford3, :boolean
    remove_column :shadows, :stanford, :boolean
    remove_column :shadows, :internet, :boolean
    remove_column :shadows, :kemerling, :boolean
    remove_column :shadows, :runes, :boolean
    remove_column :shadows, :populate, :boolean
    remove_column :shadows, :inpho, :integer
    remove_column :shadows, :inphobool, :boolean
    remove_column :shadows, :gender, :string
    remove_column :shadows, :philosopher, :integer

    # Remove Work-only columns (10 columns)
    remove_column :shadows, :pub, :string
    remove_column :shadows, :pub_year, :string
    remove_column :shadows, :pub_approx, :string
    remove_column :shadows, :work_lang, :string
    remove_column :shadows, :copyright, :string
    remove_column :shadows, :genre, :boolean
    remove_column :shadows, :obsolete, :boolean
    remove_column :shadows, :philrecord, :string
    remove_column :shadows, :philtopic, :string
    remove_column :shadows, :britannica, :string
    remove_column :shadows, :image, :string
    remove_column :shadows, :philosophical, :integer

    # Remove obsolete columns (4 columns)
    remove_column :shadows, :metric, :float
    remove_column :shadows, :metric_pos, :integer
    remove_column :shadows, :dbpedia_pagerank, :float
    remove_column :shadows, :oxford, :boolean
  end

  def down
    # Re-add Philosopher-only columns
    add_column :shadows, :birth, :string
    add_column :shadows, :birth_approx, :boolean, default: false
    add_column :shadows, :birth_year, :integer
    add_column :shadows, :death, :string
    add_column :shadows, :death_approx, :boolean, default: false
    add_column :shadows, :death_year, :integer
    add_column :shadows, :floruit, :string
    add_column :shadows, :period, :string
    add_column :shadows, :dbpedia, :boolean, default: false
    add_column :shadows, :oxford2, :boolean, default: false
    add_column :shadows, :oxford3, :boolean, default: false
    add_column :shadows, :stanford, :boolean, default: false
    add_column :shadows, :internet, :boolean, default: false
    add_column :shadows, :kemerling, :boolean, default: false
    add_column :shadows, :runes, :boolean, default: false
    add_column :shadows, :populate, :boolean, default: false
    add_column :shadows, :inpho, :integer, default: 0
    add_column :shadows, :inphobool, :boolean, default: false
    add_column :shadows, :gender, :string
    add_column :shadows, :philosopher, :integer, default: 0

    # Re-add Work-only columns
    add_column :shadows, :pub, :string
    add_column :shadows, :pub_year, :string
    add_column :shadows, :pub_approx, :string
    add_column :shadows, :work_lang, :string
    add_column :shadows, :copyright, :string
    add_column :shadows, :genre, :boolean, default: false, null: false
    add_column :shadows, :obsolete, :boolean, default: false, null: false
    add_column :shadows, :philrecord, :string
    add_column :shadows, :philtopic, :string
    add_column :shadows, :britannica, :string
    add_column :shadows, :image, :string
    add_column :shadows, :philosophical, :integer

    # Re-add obsolete columns
    add_column :shadows, :metric, :float
    add_column :shadows, :metric_pos, :integer
    add_column :shadows, :dbpedia_pagerank, :float
    add_column :shadows, :oxford, :boolean, default: false

    # Restore data from attribute tables
    execute <<-SQL
      UPDATE shadows
      SET birth = philosopher_attrs.birth,
          birth_approx = philosopher_attrs.birth_approx,
          birth_year = philosopher_attrs.birth_year,
          death = philosopher_attrs.death,
          death_approx = philosopher_attrs.death_approx,
          death_year = philosopher_attrs.death_year,
          floruit = philosopher_attrs.floruit,
          period = philosopher_attrs.period,
          dbpedia = philosopher_attrs.dbpedia,
          oxford2 = philosopher_attrs.oxford2,
          oxford3 = philosopher_attrs.oxford3,
          stanford = philosopher_attrs.stanford,
          internet = philosopher_attrs.internet,
          kemerling = philosopher_attrs.kemerling,
          runes = philosopher_attrs.runes,
          populate = philosopher_attrs.populate,
          inpho = philosopher_attrs.inpho,
          inphobool = philosopher_attrs.inphobool,
          gender = philosopher_attrs.gender,
          philosopher = philosopher_attrs.philosopher
      FROM philosopher_attrs
      WHERE shadows.id = philosopher_attrs.shadow_id
    SQL

    execute <<-SQL
      UPDATE shadows
      SET pub = work_attrs.pub,
          pub_year = work_attrs.pub_year,
          pub_approx = work_attrs.pub_approx,
          work_lang = work_attrs.work_lang,
          copyright = work_attrs.copyright,
          genre = work_attrs.genre,
          obsolete = work_attrs.obsolete,
          philrecord = work_attrs.philrecord,
          philtopic = work_attrs.philtopic,
          britannica = work_attrs.britannica,
          image = work_attrs.image,
          philosophical = work_attrs.philosophical
      FROM work_attrs
      WHERE shadows.id = work_attrs.shadow_id
    SQL

    execute <<-SQL
      UPDATE shadows
      SET metric = obsolete_attrs.metric,
          metric_pos = obsolete_attrs.metric_pos,
          dbpedia_pagerank = obsolete_attrs.dbpedia_pagerank,
          oxford = obsolete_attrs.oxford
      FROM obsolete_attrs
      WHERE shadows.id = obsolete_attrs.shadow_id
    SQL
  end
end

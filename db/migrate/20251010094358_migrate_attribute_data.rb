class MigrateAttributeData < ActiveRecord::Migration
  def up
    # Migrate Philosopher attributes
    execute <<-SQL
      INSERT INTO philosopher_attrs (
        shadow_id, birth, birth_approx, birth_year, death, death_approx,
        death_year, floruit, period, dbpedia, oxford2, oxford3, stanford,
        internet, kemerling, runes, populate, inpho, inphobool, gender,
        philosopher, created_at, updated_at
      )
      SELECT
        id, birth, birth_approx, birth_year, death, death_approx,
        death_year, floruit, period, dbpedia, oxford2, oxford3, stanford,
        internet, kemerling, runes, populate, inpho, inphobool, gender,
        philosopher, created_at, updated_at
      FROM shadows
      WHERE type = 'Philosopher'
    SQL

    # Migrate Work attributes
    execute <<-SQL
      INSERT INTO work_attrs (
        shadow_id, pub, pub_year, pub_approx, work_lang, copyright,
        genre, obsolete, philrecord, philtopic, britannica, image,
        philosophical, created_at, updated_at
      )
      SELECT
        id, pub, pub_year, pub_approx, work_lang, copyright,
        genre, obsolete, philrecord, philtopic, britannica, image,
        philosophical, created_at, updated_at
      FROM shadows
      WHERE type = 'Work'
    SQL

    # Migrate obsolete attributes for both types
    execute <<-SQL
      INSERT INTO obsolete_attrs (
        shadow_id, shadow_type, metric, metric_pos, dbpedia_pagerank,
        oxford, created_at, updated_at
      )
      SELECT
        id, type, metric, metric_pos, dbpedia_pagerank,
        oxford, created_at, updated_at
      FROM shadows
      WHERE type IN ('Philosopher', 'Work')
    SQL
  end

  def down
    # Clear the attribute tables on rollback
    execute "DELETE FROM philosopher_attrs"
    execute "DELETE FROM work_attrs"
    execute "DELETE FROM obsolete_attrs"
  end
end

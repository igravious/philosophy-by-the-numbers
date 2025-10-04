
# 2.4.0 :003 > Philosopher.all.size
#   (17.4ms)  SELECT COUNT(*) FROM "shadows" WHERE "shadows"."type" IN ('Philosopher')
# => 13230 
# 2.4.0 :004 > Philosopher.where(viaf: nil).size
#   (15.4ms)  SELECT COUNT(*) FROM "shadows" WHERE "shadows"."type" IN ('Philosopher') AND "shadows"."viaf" IS NULL
#  => 2839

Rails.logger.info(local_variables)

#   Philosopher Load (0.2ms)  SELECT  "shadows".* FROM "shadows" WHERE "shadows"."type" IN ('Philosopher') AND "shadows"."id" = ? LIMIT 1  [["id", 5489]]
#    => #<Philosopher id: 5489, type: "Philosopher", entity_id: 859, created_at: "2017-05-13 14:24:46", updated_at: "2019-03-02 14:37:54", linkcount: 248, philosophy: 48, philosopher: 77, metric: 421558.76373910345, dbpedia_pagerank: 244.698, routledge: true, populate: true, dbpedia: true, birth: "-426-01-01T00:00:00Z", death: "-346-01-01T00:00:00Z", date_hack: nil, oxford: true, birth_year: -426, death_year: -346, viaf: "108159964", metric_pos: 1, kemerling: true, what_label: nil, name_hack: nil, stanford: true, birth_approx: false, death_approx: false, floruit: nil, period: "http://www.wikidata.org/entity/Q428995", runes: true, cambridge: true, gender: "Q6581097", internet: true, borchert: true, measure: 4953315.473934466, measure_pos: 1>

all_names = @all.select('shadows.*, names.lang, names.label').joins(:names)
phils = all_names.where('names.lang = ?', 'en').order(measure: :desc)

json.array!(phils) do |phil|
	json.extract! phil, :entity_id, :viaf, :measure_pos, :lang, :label
end

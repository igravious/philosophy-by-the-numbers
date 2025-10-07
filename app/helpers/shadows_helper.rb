# app/helpers/shadows_helper.rb

module ShadowsHelper

	def make_safe(str)
		str.gsub(' ','&nbsp;').html_safe
	end

	require 'knowledge'
	include Knowledge

	def do_english(entity_id)
		cache_lookup({:entity_id => entity_id}, :entity_id)
	end

	def init_english(entity_id)
		entity = Shadow.find_by(entity_id: entity_id)
		cache_lookup(entity, :entity_id){|q|
			entity.english
		}
	end

	def do_q(model, attribute)
		cache_lookup(model, attribute){|q|
			site,title = Wikidata::API::wiki_title(q)
			title
		}
	end

	def cache_lookup(model, attribute)
		id = model[attribute]
		q = id
		case id
		when Integer
			q = "Q#{id}"
		else
		end
		fn = "db/wikidata_#{attribute}.json"
		begin
			xlate = JSON.parse(File.read(fn))
		rescue Errno::ENOENT, JSON::ParserError
			xlate = {}
		end
		if xlate.key?(q)
			title = xlate[q]
		else
			if q.nil? or q.blank?
				title = ''
			else
				title = yield q
				xlate[q] = title
				File.write(fn,xlate.to_json)
			end
		end
		raw title.gsub(' ','&nbsp;')
	end

	def wikidata_entity_url(id, show=nil)
		q = id
		case id
		when Integer
			q = "Q#{id}"
		else
		end
		if show.nil?
			if q.nil? or q.blank?
				''
			else
				link_to q, "https://www.wikidata.org/wiki/#{q}", target: "_blank"
			end
		else
			link_to make_safe(show), "https://www.wikidata.org/wiki/#{q}", target: "_blank"
		end
	end

	def wikipedia_entity_url(w_label, w_lang, label)
		lang = (w_lang.blank? ? '' : w_lang+'.')
		link_to make_safe(label), "https://#{lang}wikipedia.org/wiki/#{w_label.gsub(' ','_')}", target: "_blank"
	end

	def wikidata_property_url(id, show=nil)
		p = id
		case id
		when Integer
			p = "P#{id}"
		else
		end
		if show.nil?
			if p.nil? or p.blank?
				''
			else
				link_to p, "https://www.wikidata.org/wiki/Property:#{p}", target: "_blank"
			end
		else
			link_to make_safe(show), "https://www.wikidata.org/wiki/Property:#{p}", target: "_blank"
		end
	end

	def wikidata_type(type)
		type_to_entity = {
			'Philosopher' => 4964182
		}
		if type_to_entity.key?(type)
			wikidata_entity_url(type_to_entity[type], type)
		else
			type
		end
	end

	def p_extra # ? wrong place
		{
			type: @type,
			lang: @lang,
			metric: @metric,
			label: @label,
			toggle: @toggle,
			viaf: on_off(@viaf),         # two mutually exclusive check boxes to make {both, v ~v}
			no_viaf: on_off(@no_viaf),   # "
			living: on_off(@living),
			all_ticked: on_off(@all_ticked),
			gender: symbol_or_blank(@gender, :f, :m),
		}
	end

	def w_extra # ? wrong place
		{
			lang: @lang,
		}
	end

end # module ShadowHelper


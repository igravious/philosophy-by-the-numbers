module ApplicationHelper
	def toggleable(column, title = nil, extra = nil)
		title ||= column.titleize
		# set class attr
		css_class = column == toggle_column ? "current #{toggle_state}" : nil
		# set state attr
		state = if column == toggle_column
			# flip it for the next time
			toggle_state == 'on' ? 'off' : 'on'
		end
		if extra.nil?
			extra = {}
		end
		extra[:toggle] = column
		extra[:toggle_state] = state
		raw "<label for='#{column}'><input id='#{column}' name='toggle-#{column}' type=checkbox #{}><span class='checkable' style='margin-right: 0'></span></label>"
				+ link_to(title, extra, {:class => css_class})
	end

	def sortable(column, title = nil, extra = nil)
		title ||= column.titleize
		# set class attr
		css_class = column == sort_column ? "current #{sort_direction}" : nil
		# set dir attr
		direction = if column == sort_column
			# flip it for next time
			sort_direction == "desc" ? "asc" : "desc"
		else
			sort_it(column)
		end
		if extra.nil?
			extra = {}
		end
		extra[:sort] = column
		extra[:direction] = direction
		link_to title, extra, {:class => css_class}
	end

	def on_off(switch)
		(switch == 'checked') ? 'on' : 'off'
	end

	def symbol_or_blank(h, *syms)
		syms.each { |sym|
			return sym.to_s if h.key?(sym)
		}
		''
	end

	def title(page_title)
		  content_for :title, page_title.to_s
	end

	def truncate(label, length, word_break=true)
		if label.length > length
			parts = label.split
			len = 0
			str = ''
			i = 0
			parts.each_with_index{ |part,idx|
				break if (len+part.length) > length
				len += (part.length+1)
				str += (part+' ')
				i = idx+1
			}
			if word_break
				part = parts[i]
				str+(part[0..part.length/2])+'…'
			else
				str+' …'
			end
		else
			label
		end
	end
end

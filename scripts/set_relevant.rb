r_s = Role.all

i = 0

r_s.each do |r|
	e_id = r.entity_id
	lbl = r.label
	l = Capacity.where(entity_id: e_id).length
	if l == 0
		c = Capacity.new
		c.entity_id = e_id
		c.label = lbl
		c.save
		puts lbl
		i += 1
	end
end

puts "#{i} roles added"

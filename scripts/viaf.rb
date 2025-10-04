
Shadow.none
max = Philosopher.count
i = 1

while i < max
	v = Philosopher.where(viaf: nil, id: Philosopher.order('metric desc').limit(i)).count
	puts "#{i} . #{v}"
	i += 50
end

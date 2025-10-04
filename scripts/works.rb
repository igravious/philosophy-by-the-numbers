
def fuck_it
	puts "Please specify one parameter, a number between 1 and #{MAX_PHIL/CHUNK}"
end

MAX_PHIL = 1300
CHUNK = 25
if 1 != ARGV.length
	fuck_it
	exit
else
	idx = ARGV[0].to_i
	if 0 == idx or idx > MAX_PHIL/CHUNK
		fuck_it
		exit
	end
end

Shadow.none
phils = Philosopher.order('metric desc').limit(CHUNK).offset((idx-1)*CHUNK)
# bin/rake shadow:work:smurf[12431]
# # Q859 	Plato
phils.each do |p|
	puts "bin/rake shadow:work:snarf[#{p.id}]"
	puts "# Q#{p.entity_id.to_s.ljust(9)} #{Name.find_by(shadow_id: p.id, lang: 'en').label}"
end

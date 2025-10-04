
l_all = Labeling.all.pluck(:tag_id, :text_id)
a = {}
b = {}

l_all.each do |i|
	p i
	tag = i[0]
	text = i[1]
	if a.has_key?(tag)
		a[tag] = a[tag].push(text)
	else
		a[tag] = [text]
	end
	if b.has_key?(text)
		b[text] = b[text].push(tag)
	else
		b[text] = [tag]
	end
end
p a
p b

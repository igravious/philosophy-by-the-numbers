
# test delivery

def test_delivery()

	require 'delivery'

	d = Delivery.new

	d.numbered = 13
	d.amount = 256
	d.play = 'dramatos(?) versus ergos'

	d.identifier = 'Test Delivery'
	d.location = 'Utopia'
	d.date = '29 August 2016'

	require 'texify'

	texify(d)
end

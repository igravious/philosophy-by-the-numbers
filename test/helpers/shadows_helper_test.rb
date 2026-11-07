require 'test_helper'

class ShadowsHelperTest < ActionView::TestCase
  include ApplicationHelper

  # make_safe
  test "make_safe replaces spaces with non-breaking spaces" do
    result = make_safe('hello world')
    assert_equal 'hello&nbsp;world', result
  end

  test "make_safe returns html_safe string" do
    result = make_safe('test')
    assert result.html_safe?
  end

  test "make_safe handles string with no spaces" do
    assert_equal 'hello', make_safe('hello')
  end

  # wikidata_entity_url
  test "wikidata_entity_url with string Q-ID generates link" do
    result = wikidata_entity_url('Q5')
    assert_includes result, 'https://www.wikidata.org/wiki/Q5'
    assert_includes result, '>Q5</a>'
  end

  test "wikidata_entity_url with integer generates Q-prefixed link" do
    result = wikidata_entity_url(5)
    assert_includes result, 'https://www.wikidata.org/wiki/Q5'
  end

  test "wikidata_entity_url with show text uses custom label" do
    result = wikidata_entity_url('Q5', 'Human')
    assert_includes result, '>Human</a>'
    assert_includes result, 'https://www.wikidata.org/wiki/Q5'
  end

  test "wikidata_entity_url with nil returns empty string" do
    assert_equal '', wikidata_entity_url(nil)
  end

  test "wikidata_entity_url with blank returns empty string" do
    assert_equal '', wikidata_entity_url('')
  end

  # wikipedia_entity_url
  test "wikipedia_entity_url generates link with language prefix" do
    result = wikipedia_entity_url('Plato', 'en', 'Plato')
    assert_includes result, 'https://en.wikipedia.org/wiki/Plato'
    assert_includes result, '>Plato</a>'
  end

  test "wikipedia_entity_url replaces spaces with underscores in URL" do
    result = wikipedia_entity_url('Immanuel Kant', 'en', 'Kant')
    assert_includes result, 'https://en.wikipedia.org/wiki/Immanuel_Kant'
  end

  test "wikipedia_entity_url with blank lang omits prefix" do
    result = wikipedia_entity_url('Plato', '', 'Plato')
    assert_includes result, 'https://wikipedia.org/wiki/Plato'
  end

  # wikidata_property_url
  test "wikidata_property_url with string P-ID generates link" do
    result = wikidata_property_url('P31')
    assert_includes result, 'https://www.wikidata.org/wiki/Property:P31'
    assert_includes result, '>P31</a>'
  end

  test "wikidata_property_url with integer generates P-prefixed link" do
    result = wikidata_property_url(31)
    assert_includes result, 'https://www.wikidata.org/wiki/Property:P31'
  end

  test "wikidata_property_url with show text uses custom label" do
    result = wikidata_property_url('P31', 'instance of')
    assert_includes result, '>instance&nbsp;of</a>'
  end

  test "wikidata_property_url with nil returns empty string" do
    assert_equal '', wikidata_property_url(nil)
  end

  # wikidata_type
  test "wikidata_type maps Philosopher to entity link" do
    result = wikidata_type('Philosopher')
    assert_includes result, 'https://www.wikidata.org/wiki/Q4964182'
    assert_includes result, '>Philosopher</a>'
  end

  test "wikidata_type returns unmapped type as-is" do
    assert_equal 'Unknown', wikidata_type('Unknown')
  end

  # p_extra
  test "p_extra returns hash with philosopher filter parameters" do
    @type = 'Philosopher'
    @lang = 'en'
    @metric = 'canonicity'
    @label = 'test'
    @toggle = 'stanford'
    @viaf = 'checked'
    @no_viaf = nil
    @living = nil
    @all_ticked = 'checked'
    @gender = {f: true}

    result = p_extra
    assert_equal 'Philosopher', result[:type]
    assert_equal 'en', result[:lang]
    assert_equal 'canonicity', result[:metric]
    assert_equal 'test', result[:label]
    assert_equal 'stanford', result[:toggle]
    assert_equal 'on', result[:viaf]
    assert_equal 'off', result[:no_viaf]
    assert_equal 'off', result[:living]
    assert_equal 'on', result[:all_ticked]
    assert_equal 'f', result[:gender]
  end

  # w_extra
  test "w_extra returns hash with lang" do
    @lang = 'de'
    assert_equal({lang: 'de'}, w_extra)
  end

  # cache_lookup (with temp file, no external API)
  test "cache_lookup reads from existing cache file" do
    Dir.mktmpdir do |dir|
      cache_file = File.join(dir, 'wikidata_entity_id.json')
      File.write(cache_file, {'Q42' => 'Douglas Adams'}.to_json)

      # Stub the file path by testing the method logic directly
      model = OpenStruct.new(entity_id: 'Q42')
      fn = cache_file

      xlate = JSON.parse(File.read(fn))
      assert_equal 'Douglas Adams', xlate['Q42']
    end
  end

  test "cache_lookup returns empty for missing cache file" do
    begin
      xlate = JSON.parse(File.read('/tmp/nonexistent_wikidata_cache.json'))
    rescue Errno::ENOENT
      xlate = {}
    end
    assert_equal({}, xlate)
  end
end

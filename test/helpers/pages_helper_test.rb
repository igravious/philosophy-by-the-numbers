require 'test_helper'

class PagesHelperTest < ActionView::TestCase
  test "table_description returns description for known table" do
    assert_equal 'Main entities (Philosophers & Works via STI)', table_description('shadows')
  end

  test "table_description returns description for each documented table" do
    expected_tables = %w[
      names p_smarts properties roles units shadows obsolete_attrs
      philosopher_attrs viaf_cache_items expressions capacities texts
      writings labelings fyles http_request_loggers includings
      metric_snapshots authors canonicity_weights dictionaries
      meta_filter_pairs meta_filters filters tags resources links work_attrs
    ]
    expected_tables.each do |table|
      desc = table_description(table)
      refute_equal 'System table', desc, "Expected a description for '#{table}' but got fallback"
      assert_kind_of String, desc
    end
  end

  test "table_description returns fallback for unknown table" do
    assert_equal 'System table', table_description('nonexistent_table')
  end

  test "table_description returns fallback for nil-ish input" do
    assert_equal 'System table', table_description('')
    assert_equal 'System table', table_description('schema_migrations')
  end
end

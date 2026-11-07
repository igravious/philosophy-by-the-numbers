require "test_helper"
require_relative "../../scripts/zotero_cluster"

class ZoteroClusterInventoryTest < ActiveSupport::TestCase
  test "multiple videos receive distinct artifact IDs" do
    by_key = {
      "B" => {"data" => {"itemType" => "videoRecording", "url" => ""}},
      "A" => {"data" => {"itemType" => "videoRecording", "url" => ""}}
    }

    inventory = ZoteroCluster.inventory_for(%w[A B], by_key, "EP-999")
    video_ids = inventory.map { |entry| entry["id"] }.grep(%r{/video/})

    assert_equal ["EP-999/video/main", "EP-999/video/other-1"], video_ids
    assert_equal video_ids.uniq, video_ids
  end
end

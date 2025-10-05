namespace :danker do
  desc "Check latest danker data version and download if needed"
  task :update => :environment do
    require 'net/http'
    require 'nokogiri'
    require 'fileutils'
    
    danker_url = 'https://danker.s3.amazonaws.com/index.html'
    danker_base_dir = Rails.root.join('db')
    
    puts "Checking latest danker data from #{danker_url}..."
    
    begin
      # Fetch the index page
      uri = URI(danker_url)
      response = Net::HTTP.get_response(uri)
      
      if response.code != '200'
        puts "ERROR: Could not fetch danker index page (HTTP #{response.code})"
        exit 1
      end
      
      # Parse HTML to find available datasets
      doc = Nokogiri::HTML(response.body)
      
      # Look for URLs in the HTML content that match the danker file pattern
      html_content = doc.text
      rank_file_urls = html_content.scan(/https:\/\/danker\.s3\.amazonaws\.com\/(\d{4}-\d{2}-\d{2})\.allwiki\.links\.rank\.bz2/)
      
      # Extract unique dates from the matched URLs
      date_dirs = rank_file_urls.flatten.uniq.sort.reverse
      
      if date_dirs.empty?
        puts "ERROR: No danker data files found on index page"
        exit 1
      end
      
      latest_version = date_dirs.first.chomp('/')
      puts "Latest danker version: #{latest_version}"
      
      # Check if we already have this version
      local_version_dir = danker_base_dir.join("danker_#{latest_version}")
      symlink_path = danker_base_dir.join('danker')
      
      if local_version_dir.exist?
        puts "✓ Already have latest version: #{latest_version}"
        
        # Ensure symlink points to latest
        if symlink_path.exist? || symlink_path.symlink?
          FileUtils.rm(symlink_path)
        end
        FileUtils.ln_s("danker_#{latest_version}", symlink_path)
        puts "✓ Symlink updated to point to danker_#{latest_version}"
        
        # Verify the data file format
        verify_danker_data_format(local_version_dir)
      else
        puts "⬇ Downloading danker data for #{latest_version}..."
        download_danker_data(latest_version, local_version_dir, symlink_path)
      end
      
    rescue => e
      puts "ERROR: #{e.message}"
      puts e.backtrace.first(5)
      exit 1
    end
  end
  
  desc "List available danker data versions"
  task :list => :environment do
    danker_base_dir = Rails.root.join('db')
    
    # Find all danker_* directories
    danker_dirs = Dir.glob(danker_base_dir.join('danker_*')).select { |d| File.directory?(d) }
    
    if danker_dirs.any?
      versions = danker_dirs.map { |d| File.basename(d).sub(/^danker_/, '') }.sort.reverse
      
      puts "Available danker data versions:"
      versions.each do |version|
        marker = ""
        symlink_path = danker_base_dir.join('danker')
        if symlink_path.symlink? && symlink_path.readlink.to_s == "danker_#{version}"
          marker = " <- current"
        end
        puts "  #{version}#{marker}"
      end
    else
      puts "No danker data found. Run 'rake danker:update' to download."
    end
  end
  
  private
  
  def download_danker_data(version, local_dir, symlink_path)
    require 'open-uri'
    
    # Create directory
    FileUtils.mkdir_p(local_dir)
    
    # New danker file patterns to download
    file_patterns = [
      "#{version}.allwiki.links.rank.bz2",
      "#{version}.allwiki.links.stats.txt"
    ]
    
    base_url = "https://danker.s3.amazonaws.com/"
    downloaded_files = []
    
    file_patterns.each do |filename|
      file_url = base_url + filename
      local_file = local_dir.join(filename)
      
      begin
        puts "  Downloading #{filename}..."
        URI.open(file_url) do |remote_file|
          File.open(local_file, 'wb') do |local_file_handle|
            local_file_handle.write(remote_file.read)
          end
        end
        downloaded_files << filename
        puts "    ✓ #{filename} (#{File.size(local_file)} bytes)"
      rescue => e
        puts "    ⚠ Could not download #{filename}: #{e.message}"
      end
    end
    
    if downloaded_files.empty?
      puts "ERROR: No files downloaded for version #{version}"
      FileUtils.rm_rf(local_dir)
      exit 1
    end
    
    # Update symlink
    if symlink_path.exist? || symlink_path.symlink?
      FileUtils.rm(symlink_path)
    end
    FileUtils.ln_s("danker_#{version}", symlink_path)
    puts "✓ Created symlink to danker_#{version}"
    
    # Verify data format
    verify_danker_data_format(local_dir)
    
    puts "✓ Successfully downloaded and configured danker data #{version}"
  end
  
  def verify_danker_data_format(data_dir)
    # Look for the new compressed rank files
    rank_files = Dir.glob(data_dir.join('*.rank.bz2'))
    
    if rank_files.empty?
      puts "⚠ Warning: No .rank.bz2 files found in #{data_dir}"
      return false
    end
    
    rank_file = rank_files.first
    puts "Verifying data format in #{File.basename(rank_file)}..."
    
    # Check if we can decompress and read the file
    begin
      # Try to read a few lines from the compressed file
      require 'bzip2-ffi'
      
      line_count = 0
      valid_lines = 0
      
      File.open(rank_file, 'rb') do |file|
        Bzip2::FFI::Reader.open(file) do |reader|
          reader.each_line do |line|
            line_count += 1
            break if line_count > 10  # Check first 10 lines
            
            # Expected format: Q12345\t0.123456 (tab-separated)
            if line.match?(/^Q\d+\t[\d.eE+-]+/)
              valid_lines += 1
            end
          end
        end
      end
      
      if valid_lines > 0
        puts "✓ Data format verified: #{valid_lines}/#{line_count} lines match expected format (Q###\\tscore)"
        return true
      else
        puts "⚠ Warning: Data format may be incorrect. Expected format: Q###\\tscore"
        return false
      end
      
    rescue LoadError
      puts "⚠ Warning: bzip2-ffi gem not available, cannot verify compressed file format"
      puts "✓ File downloaded successfully but format not verified"
      return true
    rescue => e
      puts "⚠ Warning: Could not verify file format: #{e.message}"
      return false
    end
  end

  desc "Process compressed danker files into sorted CSV format for faster lookups"
  task :process_files => :environment do
    # Find all danker directories
    danker_dirs = Dir.glob(Rails.root.join('db', 'danker_*')).sort
    
    if danker_dirs.empty?
      puts "ERROR: No danker data found. Run 'rake danker:update' first."
      exit 1
    end
    
    danker_dirs.each do |dir|
      version = File.basename(dir)
      puts "\nProcessing danker data: #{version}"
      
      # Look for compressed rank file
      bz2_files = Dir.glob(File.join(dir, '*.rank.bz2'))
      if bz2_files.empty?
        puts "⚠ Skipping #{version}: no .rank.bz2 file found"
        next
      end
      
      bz2_file = bz2_files.first
      base_name = File.basename(bz2_file, '.bz2')  # removes .bz2
      
      # Output files
      rank_file = File.join(dir, base_name)  # 2025-09-05.allwiki.links.rank
      alphanum_file = File.join(dir, base_name.gsub('.rank', '.c.alphanum'))
      csv_file = File.join(dir, base_name.gsub('.rank', '.c.alphanum.csv'))
      
      puts "  Input:  #{File.basename(bz2_file)}"
      puts "  Output: #{File.basename(csv_file)}"
      
      # Skip if CSV already exists and is newer than bz2
      if File.exist?(csv_file) && File.mtime(csv_file) > File.mtime(bz2_file)
        puts "  ✓ CSV file already exists and is up to date"
        next
      end
      
      begin
        # Generate all four files like the original process:
        # 1. .rank (decompressed)
        # 2. .q (sorted by Q-number) 
        # 3. .c.alphanum (sorted alphabetically for binary search)
        # 4. .c.alphanum.csv (CSV format for look command)
        
        q_file = File.join(dir, base_name.gsub('.rank', '.q'))
        
        # Step 1: Decompress the bz2 file
        puts "  → Decompressing..."
        system("bzcat '#{bz2_file}' > '#{rank_file}'")
        
        unless File.exist?(rank_file)
          puts "  ✗ Failed to decompress file"
          next
        end
        
        # Step 2: Sort by Q-number (numerical order) for .q file
        puts "  → Sorting by Q-number..."
        system("LC_COLLATE=C sort -k1,1V '#{rank_file}' > '#{q_file}'")
        
        unless File.exist?(q_file)
          puts "  ✗ Failed to create Q-sorted file"
          next
        end
        
        # Step 3: Sort alphabetically for binary search (.c.alphanum)
        puts "  → Sorting alphabetically for binary search..."
        system("LC_COLLATE=C sort -d '#{rank_file}' > '#{alphanum_file}'")
        
        unless File.exist?(alphanum_file)
          puts "  ✗ Failed to sort alphabetically"
          next
        end
        
        # Step 4: Convert tabs to commas for CSV format (.c.alphanum.csv)
        puts "  → Converting to CSV format..."
        system("sed 's/\t/,/g' '#{alphanum_file}' > '#{csv_file}'")
        
        unless File.exist?(csv_file)
          puts "  ✗ Failed to create CSV file"
          next
        end
        
        # Verify all files have correct line counts
        original_lines = `wc -l < '#{rank_file}'`.strip.to_i
        q_lines = `wc -l < '#{q_file}'`.strip.to_i
        alphanum_lines = `wc -l < '#{alphanum_file}'`.strip.to_i
        csv_lines = `wc -l < '#{csv_file}'`.strip.to_i
        
        if original_lines == q_lines && original_lines == alphanum_lines && original_lines == csv_lines
          puts "  ✓ Successfully processed #{csv_lines} records"
          puts "    Files created:"
          puts "      #{File.basename(rank_file)} (original decompressed)"
          puts "      #{File.basename(q_file)} (Q-number sorted)"
          puts "      #{File.basename(alphanum_file)} (alphabetically sorted)"
          puts "      #{File.basename(csv_file)} (CSV for binary search)"
        else
          puts "  ✗ Line count mismatch: orig=#{original_lines}, q=#{q_lines}, alpha=#{alphanum_lines}, csv=#{csv_lines}"
        end
        
      rescue => e
        puts "  ✗ Error processing #{version}: #{e.message}"
      end
    end
    
    puts "\n✓ Danker file processing completed"
  end
end
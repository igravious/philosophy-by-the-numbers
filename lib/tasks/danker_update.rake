namespace :danker do
  desc "Check latest danker data version and download if needed"
  task :update => :environment do
    require 'net/http'
    require 'nokogiri'
    require 'fileutils'
    
    danker_url = 'https://danker.s3.amazonaws.com/index.html'
    danker_dir = Rails.root.join('db', 'danker')
    
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
      links = doc.css('a').map { |link| link['href'] }.compact
      
      # Find directories that match date pattern (YYYY-MM-DD format)
      date_dirs = links.select { |link| link.match?(/\d{4}-\d{2}-\d{2}/) }.sort.reverse
      
      if date_dirs.empty?
        puts "ERROR: No dated directories found on danker index page"
        exit 1
      end
      
      latest_version = date_dirs.first.chomp('/')
      puts "Latest danker version: #{latest_version}"
      
      # Check if we already have this version
      local_version_dir = danker_dir.join(latest_version)
      symlink_path = danker_dir.join('latest')
      
      if local_version_dir.exist?
        puts "✓ Already have latest version: #{latest_version}"
        
        # Ensure symlink points to latest
        if symlink_path.exist? || symlink_path.symlink?
          FileUtils.rm(symlink_path)
        end
        FileUtils.ln_s(latest_version, symlink_path)
        puts "✓ Symlink updated to point to #{latest_version}"
        
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
    danker_dir = Rails.root.join('db', 'danker')
    
    if danker_dir.exist?
      versions = Dir.glob(danker_dir.join('20*')).map { |d| File.basename(d) }.sort.reverse
      
      puts "Available danker data versions:"
      versions.each do |version|
        marker = ""
        if danker_dir.join('latest').symlink? && danker_dir.join('latest').readlink.to_s == version
          marker = " <- current"
        end
        puts "  #{version}#{marker}"
      end
      
      if versions.empty?
        puts "No danker data found. Run 'rake danker:update' to download."
      end
    else
      puts "Danker directory not found. Run 'rake danker:update' to initialize."
    end
  end
  
  private
  
  def download_danker_data(version, local_dir, symlink_path)
    require 'open-uri'
    
    # Create directory
    FileUtils.mkdir_p(local_dir)
    
    # Common file patterns to download
    file_patterns = [
      "#{version}.all.links.c.alphanum.csv",
      "#{version}.all.links.rank",
      "#{version}.all.links.c.alphanum"
    ]
    
    base_url = "https://danker.s3.amazonaws.com/#{version}/"
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
    FileUtils.ln_s(version, symlink_path)
    puts "✓ Created symlink to #{version}"
    
    # Verify data format
    verify_danker_data_format(local_dir)
    
    puts "✓ Successfully downloaded and configured danker data #{version}"
  end
  
  def verify_danker_data_format(data_dir)
    csv_files = Dir.glob(data_dir.join('*.csv'))
    
    if csv_files.empty?
      puts "⚠ Warning: No CSV files found in #{data_dir}"
      return false
    end
    
    csv_file = csv_files.first
    puts "Verifying data format in #{File.basename(csv_file)}..."
    
    # Check first few lines
    line_count = 0
    valid_lines = 0
    
    File.open(csv_file, 'r') do |file|
      file.each_line do |line|
        line_count += 1
        break if line_count > 10  # Check first 10 lines
        
        # Expected format: Q12345,0.123456
        if line.match?(/^Q\d+,[\d.]+/)
          valid_lines += 1
        end
      end
    end
    
    if valid_lines > 0
      puts "✓ Data format verified: #{valid_lines}/#{line_count} lines match expected format (Q###,score)"
      return true
    else
      puts "⚠ Warning: Data format may be incorrect. Expected format: Q###,score"
      return false
    end
  end
end
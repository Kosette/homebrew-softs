# frozen_string_literal: true

# brew-createzap.rb
#
# Homebrew external command: brew createzap <application-name>
#
# Generates a Homebrew Cask zap stanza by scanning common macOS
# preference and support locations for files matching the given
# application name (and its bundle identifier if discoverable).
#
# Usage:
#   brew createzap Raycast
#   brew createzap "Visual Studio Code"

module Homebrew
  module_function

  SEARCH_PATHS = [
    "#{Dir.home}/Desktop",
    "#{Dir.home}/Documents",
    "#{Dir.home}/Library",
    "#{Dir.home}/Library/Application Scripts",
    "#{Dir.home}/Library/Application Support",
    "#{Dir.home}/Library/Application Support/com.apple.sharedfilelist/" \
      "com.apple.LSSharedFileList.ApplicationRecentDocuments",
    "#{Dir.home}/Library/Caches",
    "#{Dir.home}/Library/Caches/com.apple.helpd/Generated",
    "#{Dir.home}/Library/Caches/com.apple.helpd/SDMHelpData/Other/English/HelpSDMIndexFile",
    "#{Dir.home}/Library/Containers",
    "#{Dir.home}/Library/Cookies",
    "#{Dir.home}/Library/Group Containers",
    "#{Dir.home}/Library/HTTPStorages",
    "#{Dir.home}/Library/Internet Plug-Ins",
    "#{Dir.home}/Library/LaunchAgents",
    "#{Dir.home}/Library/Logs",
    "#{Dir.home}/Library/PreferencePanes",
    "#{Dir.home}/Library/Preferences",
    "#{Dir.home}/Library/Saved Application State",
    "#{Dir.home}/Library/WebKit",
    "#{Dir.home}/Music",
    "/Library/Application Support",
    "/Library/Caches",
    "/Library/LaunchDaemons",
    "/Library/PreferencePanes",
    "/Library/Preferences",
    "/Library/PrivilegedHelperTools",
    "/Library/Screen Savers",
    "/Library/ScriptingAdditions",
    "/Library/Services",
    "/Users/Shared",
    "/etc/newsyslog.d",
  ].freeze

  # Try to read CFBundleIdentifier from a matching .app bundle.
  # Returns the bundle identifier string, or nil if not found.
  def get_bundle_id(app_name)
    candidates = [
      "/Applications/#{app_name}.app",
      "#{Dir.home}/Applications/#{app_name}.app",
    ]

    candidates.each do |app_path|
      next unless File.directory?(app_path)

      plist = "#{app_path}/Contents/Info.plist"
      next unless File.exist?(plist)

      # Use PlistBuddy for reliable plist reading (always available on macOS)
      result = `/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "#{plist}" 2>/dev/null`.strip
      return result unless result.empty?
    end

    nil
  end

  # Returns true if +path+'s basename matches any of the search terms
  # (case-insensitive substring match).
  def path_matches?(path, search_terms)
    basename = File.basename(path)
    search_terms.any? { |term| basename.downcase.include?(term.downcase) }
  end

  # Search each configured directory non-recursively (one level deep).
  def search_locations(search_terms)
    matches = []

    SEARCH_PATHS.each do |dir|
      next unless File.directory?(dir)

      begin
        Dir.each_child(dir) do |child|
          full_path = File.join(dir, child)
          # Skip if the entry disappeared between listing and check
          next unless File.exist?(full_path)

          matches << full_path if path_matches?(full_path, search_terms)
        end
      rescue Errno::EACCES, Errno::EPERM
        # Skip directories we cannot read
        next
      end
    end

    matches
  end

  # Search the home directory at depth 1 (mirrors `find $HOME -maxdepth 1`).
  def search_home(search_terms)
    matches = []

    begin
      Dir.each_child(Dir.home) do |child|
        full_path = File.join(Dir.home, child)
        next unless File.exist?(full_path)

        matches << full_path if path_matches?(full_path, search_terms)
      end
    rescue Errno::EACCES, Errno::EPERM
      # Silently skip if $HOME is unreadable (unusual but safe to handle)
    end

    matches
  end

  # Deduplicate results with case-insensitive uniqueness, then sort.
  # Mirrors `sort -fu` behaviour: keeps the first occurrence of each
  # case-folded path, then sorts the de-duplicated list.
  def dedup_sort(paths)
    seen = {}
    paths.each do |p|
      key = p.downcase
      seen[key] ||= p
    end
    seen.values.sort_by(&:downcase)
  end

  # Replace the literal home directory prefix with ~ for display.
  def tilde_path(path)
    home = Dir.home
    if path.start_with?("#{home}/") || path == home
      path.sub(home, "~")
    else
      path
    end
  end

  def generate_output(search_terms)
    raw = search_locations(search_terms) + search_home(search_terms)
    results = dedup_sort(raw)

    if results.empty?
      puts "No matching settings found."
      puts "# No zap stanza required"
      return
    end

    display = results.map { |p| tilde_path(p) }

    if display.size == 1
      puts %(zap trash: "#{display.first}")
    else
      puts "zap trash: ["
      display.each { |item| puts %(  "#{item}",) }
      puts "]"
    end
  end

  def createzap_main(args)
    if args.size != 1
      $stderr.puts "Usage: brew createzap <application-name>"
      $stderr.puts
      $stderr.puts "Examples:"
      $stderr.puts "  brew createzap Raycast"
      $stderr.puts '  brew createzap "Visual Studio Code"'
      exit 1
    end

    app_name = args.first

    search_terms = [app_name]

    bundle_id = get_bundle_id(app_name)
    search_terms << bundle_id if bundle_id && !bundle_id.empty?

    generate_output(search_terms)
  end
end

# When invoked as a Homebrew external command the remaining ARGV
# elements after option parsing are passed through. Strip any leading
# Homebrew-injected flags (e.g. --verbose, --debug) so only the
# positional application-name argument remains.
positional_args = ARGV.reject { |a| a.start_with?("-") }
Homebrew.createzap_main(positional_args)

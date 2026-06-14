# frozen_string_literal: true

require "abstract_command"
require "system_command"

module Homebrew
  module Cmd
    # Generates a Homebrew Cask zap stanza by scanning common macOS
    # preference and support locations for files matching the given
    # application name (and its bundle identifier if discoverable).
    #
    # Usage:
    #   brew createzap Raycast
    #   brew createzap "Visual Studio Code"
    class Createzap < AbstractCommand
      include SystemCommand::Mixin

      cmd_args do
        description <<~EOS
          Generate a Homebrew Cask `zap` stanza for <application-name>.

          Scans common macOS preference and support locations for files
          matching the application name and its bundle identifier
          (discovered from the installed .app bundle's Info.plist).
        EOS

        named_args min: 1, max: 1
      end

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

      sig { override.void }
      def run
        app_name = args.named.first
        search_terms = [app_name]
        bundle_id = get_bundle_id(app_name)
        search_terms << bundle_id if bundle_id && !bundle_id.empty?
        generate_output(search_terms)
      end

      private

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

          result = system_command(
            "/usr/libexec/PlistBuddy",
            args:         ["-c", "Print CFBundleIdentifier", plist],
            print_stderr: false,
          ).stdout.strip
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
              next unless File.exist?(full_path)

              matches << full_path if path_matches?(full_path, search_terms)
            end
          rescue Errno::EACCES, Errno::EPERM
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
          # Silently skip if $HOME is unreadable
        end

        matches
      end

      # Deduplicate results with case-insensitive uniqueness, then sort.
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
    end
  end
end

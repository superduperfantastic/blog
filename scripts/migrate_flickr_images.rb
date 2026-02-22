#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "shellwords"

POSTS_GLOB = "_posts/*.md"
ASSETS_ROOT = "assets/posts"
FLICKR_HOST_PATTERN = /(?:staticflickr\.com|static\.flickr\.com|live\.staticflickr\.com)/i
URL_PATTERN = %r{https?://[^\s\)\"']+\.(?:jpg|jpeg|png|gif)}i

def usage
  puts <<~USAGE
    Usage:
      ruby scripts/migrate_flickr_images.rb [--dry-run] [_posts/file1.md _posts/file2.md ...]

    What it does:
      1) Finds Flickr image URLs in _posts/*.md
      2) Downloads each image into assets/posts/<post-slug>/
      3) Rewrites the URL in the post to the local /assets/... path

    Notes:
      - --dry-run shows planned changes without writing files.
      - Requires curl in PATH.
  USAGE
end

def find_urls(content)
  content.scan(URL_PATTERN).uniq.select { |url| url.match?(FLICKR_HOST_PATTERN) }
end

def local_folder_for(post_path)
  base = File.basename(post_path, ".md")
  File.join(ASSETS_ROOT, base)
end

def safe_filename(url)
  raw = File.basename(url.split("?").first)
  return "image.jpg" if raw.nil? || raw.empty?

  raw.gsub(/[^A-Za-z0-9.\-_]/, "_")
end

def unique_path(path)
  return path unless File.exist?(path)

  ext = File.extname(path)
  stem = path.delete_suffix(ext)
  idx = 2
  loop do
    candidate = "#{stem}-#{idx}#{ext}"
    return candidate unless File.exist?(candidate)

    idx += 1
  end
end

def download(url, target_path, dry_run:)
  if dry_run
    puts "  [dry-run] download #{url} -> #{target_path}"
    return true
  end

  cmd = [
    "curl", "-fsSL", url, "-o", target_path
  ].shelljoin

  system(cmd)
end

def migrate_post(post_path, dry_run:)
  content = File.read(post_path)
  urls = find_urls(content)
  return [0, 0] if urls.empty?

  folder = local_folder_for(post_path)
  puts "Processing #{post_path}"
  puts "  Flickr URLs found: #{urls.size}"

  FileUtils.mkdir_p(folder) unless dry_run
  updated = content.dup
  changed_count = 0

  urls.each do |url|
    filename = safe_filename(url)
    target_path = unique_path(File.join(folder, filename))
    local_ref = "/#{target_path}"

    if File.exist?(target_path)
      puts "  reuse existing #{target_path}"
    else
      ok = download(url, target_path, dry_run: dry_run)
      unless ok
        warn "  failed download: #{url}"
        next
      end
      if dry_run
        puts "  [dry-run] queued #{target_path}"
      else
        puts "  downloaded #{target_path}"
      end
    end

    next unless updated.include?(url)

    updated.gsub!(url, local_ref)
    changed_count += 1
  end

  if changed_count.positive?
    if dry_run
      puts "  [dry-run] would update #{changed_count} URL(s) in #{post_path}"
    else
      File.write(post_path, updated)
      puts "  updated #{changed_count} URL(s) in #{post_path}"
    end
  end

  [urls.size, changed_count]
end

if ARGV.include?("--help") || ARGV.include?("-h")
  usage
  exit 0
end

dry_run = ARGV.include?("--dry-run")
post_args = ARGV.reject { |arg| arg == "--dry-run" }
posts = if post_args.empty?
          Dir.glob(POSTS_GLOB).sort
        else
          post_args
        end
total_urls = 0
total_updates = 0

posts.each do |post_path|
  unless File.exist?(post_path)
    warn "Skipping missing file: #{post_path}"
    next
  end
  urls, updates = migrate_post(post_path, dry_run: dry_run)
  total_urls += urls
  total_updates += updates
end

puts
puts "Done."
puts "  Total Flickr URLs seen: #{total_urls}"
puts "  Total URL replacements: #{total_updates}"
puts "  Mode: #{dry_run ? 'dry-run' : 'write'}"

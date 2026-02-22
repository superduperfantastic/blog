#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"

POSTS_GLOB = "_posts/*.md"

def usage
  puts <<~USAGE
    Usage:
      ruby scripts/rename_post_images.rb [--write] [_posts/file1.md _posts/file2.md ...]

    Behavior:
      - Finds local image URLs that point to /assets/posts/<post-slug>/...
      - Renames those files to cleaner names
      - Rewrites URLs in the post file to match

    Naming:
      - Uses blog post name without date prefix:
        YYYY-MM-DD-my-post-title -> my-post-title
      - Front matter:
        image: my-post-title-cover.jpg
        thumbnail: my-post-title-thumb.jpg
      - In-post images numbered numerically:
        my-post-title-01.jpg, my-post-title-02.jpg, ...

    Notes:
      - Dry-run by default. Use --write to apply changes.
      - Front matter links like `image:` and `thumbnail:` are updated automatically.
  USAGE
end

def post_slug(post_path)
  File.basename(post_path, ".md")
end

def title_slug_from_post_slug(slug)
  # Strip leading date prefix if present.
  match = slug.match(/^\d{4}-\d{2}-\d{2}-(.+)$/)
  base = match ? match[1] : slug
  base.gsub(/[^A-Za-z0-9\-]/, "-").gsub(/-+/, "-").gsub(/^-|-$/, "")
end

def extract_local_urls(content, slug)
  # Capture local asset URLs for this post folder only.
  pattern = %r{/assets/posts/#{Regexp.escape(slug)}/[^\s\)"']+\.(?:jpg|jpeg|png|gif|webp|JPG|JPEG|PNG|GIF|WEBP)}
  content.scan(pattern).uniq
end

def extname_from_url(url)
  File.extname(url).downcase
end

def filename_from_url(url)
  File.basename(url)
end

def frontmatter_local_url(content, key, slug)
  raw = content[/^#{Regexp.escape(key)}:\s*(.+)\s*$/, 1]
  return nil if raw.nil?

  value = raw.strip
  return nil if value.empty?

  value = value.gsub(/\A['"]|['"]\z/, "")
  prefix = "/assets/posts/#{slug}/"
  value.start_with?(prefix) ? value : nil
end

def build_mapping(content, slug, urls)
  base = title_slug_from_post_slug(slug)
  candidates = urls.dup
  return {} if candidates.empty?

  image_url = frontmatter_local_url(content, "image", slug)
  thumb_url = frontmatter_local_url(content, "thumbnail", slug)

  mapping = {}
  used = {}

  if image_url && candidates.include?(image_url)
    ext = extname_from_url(image_url)
    mapping[image_url] = "/assets/posts/#{slug}/#{base}-cover#{ext}"
    used[image_url] = true
  end

  if thumb_url && candidates.include?(thumb_url) && !used[thumb_url]
    ext = extname_from_url(thumb_url)
    mapping[thumb_url] = "/assets/posts/#{slug}/#{base}-thumb#{ext}"
    used[thumb_url] = true
  end

  seq = 1
  ordered_content = urls.select { |u| candidates.include?(u) && !used[u] }
  ordered_content.each do |old_url|
    ext = extname_from_url(old_url)
    new_name = "#{base}-#{format('%02d', seq)}#{ext}"
    seq += 1
    new_url = "/assets/posts/#{slug}/#{new_name}"
    mapping[old_url] = new_url
  end

  mapping
end

def rename_files(mapping, dry_run:)
  used_targets = {}
  applied = {}

  mapping.each do |old_url, new_url|
    old_rel = old_url.sub(%r{^/}, "")
    new_rel = new_url.sub(%r{^/}, "")

    unless File.exist?(old_rel)
      warn "  missing file: #{old_rel} (skipping)"
      next
    end

    # Avoid collisions if two files would map to same target name.
    if used_targets[new_rel]
      ext = File.extname(new_rel)
      stem = new_rel.delete_suffix(ext)
      i = 2
      loop do
        candidate = "#{stem}-#{i}#{ext}"
        unless used_targets[candidate] || File.exist?(candidate)
          new_rel = candidate
          new_url = "/#{candidate}"
          break
        end
        i += 1
      end
    elsif File.exist?(new_rel) && File.expand_path(new_rel) != File.expand_path(old_rel)
      ext = File.extname(new_rel)
      stem = new_rel.delete_suffix(ext)
      i = 2
      loop do
        candidate = "#{stem}-#{i}#{ext}"
        unless File.exist?(candidate) || used_targets[candidate]
          new_rel = candidate
          new_url = "/#{candidate}"
          break
        end
        i += 1
      end
    end

    used_targets[new_rel] = true
    applied[old_url] = new_url

    if dry_run
      puts "  [dry-run] rename #{old_rel} -> #{new_rel}"
    else
      next if File.expand_path(old_rel) == File.expand_path(new_rel)
      FileUtils.mv(old_rel, new_rel)
      puts "  renamed #{old_rel} -> #{new_rel}"
    end
  end

  applied
end

def process_post(post_path, dry_run:)
  content = File.read(post_path)
  slug = post_slug(post_path)
  urls = extract_local_urls(content, slug)
  return [0, 0] if urls.empty?

  puts "Processing #{post_path}"
  puts "  local URLs found: #{urls.size}"

  mapping = build_mapping(content, slug, urls)
  return [urls.size, 0] if mapping.empty?
  applied_mapping = rename_files(mapping, dry_run: dry_run)
  return [urls.size, 0] if applied_mapping.empty?

  updated = content.dup
  replacements = 0
  applied_mapping.each do |old_url, new_url|
    next unless updated.include?(old_url)
    updated.gsub!(old_url, new_url)
    replacements += 1
  end

  if replacements.positive?
    if dry_run
      puts "  [dry-run] would update #{replacements} URL(s) in #{post_path}"
    else
      File.write(post_path, updated)
      puts "  updated #{replacements} URL(s) in #{post_path}"
    end
  end

  [urls.size, replacements]
end

if ARGV.include?("--help") || ARGV.include?("-h")
  usage
  exit 0
end

dry_run = !ARGV.include?("--write")
post_args = ARGV.reject { |arg| arg == "--write" }
posts = post_args.empty? ? Dir.glob(POSTS_GLOB).sort : post_args

total_urls = 0
total_updates = 0

posts.each do |post_path|
  unless File.exist?(post_path)
    warn "Skipping missing file: #{post_path}"
    next
  end

  urls, updates = process_post(post_path, dry_run: dry_run)
  total_urls += urls
  total_updates += updates
end

puts
puts "Done."
puts "  Local URLs seen: #{total_urls}"
puts "  URL replacements: #{total_updates}"
puts "  Mode: #{dry_run ? 'dry-run' : 'write'}"

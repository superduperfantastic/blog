#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "fileutils"

POSTS_GLOB = "_posts/*.md"
ASSETS_ROOT = "assets/posts"

def date_and_slug_from_post(post_path)
  base = File.basename(post_path, ".md")
  m = base.match(/^(\d{4}-\d{2}-\d{2})-(.+)$/)
  return nil, nil unless m

  [m[1], base]
end

def safe_move_file(src, dest)
  return if File.expand_path(src) == File.expand_path(dest)

  if File.exist?(dest)
    src_hash = Digest::SHA256.file(src).hexdigest
    dest_hash = Digest::SHA256.file(dest).hexdigest
    if src_hash == dest_hash
      FileUtils.rm_f(src)
      return
    end

    ext = File.extname(dest)
    stem = dest.delete_suffix(ext)
    idx = 2
    loop do
      candidate = "#{stem}-#{idx}#{ext}"
      unless File.exist?(candidate)
        dest = candidate
        break
      end
      idx += 1
    end
  end

  FileUtils.mv(src, dest)
end

def migrate_post(post_path)
  date, slug = date_and_slug_from_post(post_path)
  return [false, 0, 0] unless date && slug

  src_dir = File.join(ASSETS_ROOT, slug)
  dst_dir = File.join(ASSETS_ROOT, date)
  return [false, 0, 0] unless File.directory?(src_dir)

  FileUtils.mkdir_p(dst_dir)

  moved_files = 0
  Dir.children(src_dir).each do |entry|
    src = File.join(src_dir, entry)
    next unless File.file?(src)
    dest = File.join(dst_dir, entry)
    safe_move_file(src, dest)
    moved_files += 1
  end

  # Remove empty source directory when done.
  Dir.rmdir(src_dir) if Dir.exist?(src_dir) && Dir.empty?(src_dir)

  content = File.read(post_path)
  old_prefix = "/#{ASSETS_ROOT}/#{slug}/"
  new_prefix = "/#{ASSETS_ROOT}/#{date}/"
  replacements = content.scan(old_prefix).size
  if replacements.positive?
    content = content.gsub(old_prefix, new_prefix)
    File.write(post_path, content)
  end

  [true, moved_files, replacements]
end

total_posts = 0
total_moved = 0
total_replacements = 0

Dir.glob(POSTS_GLOB).sort.each do |post_path|
  changed, moved, replacements = migrate_post(post_path)
  next unless changed

  puts "Updated #{post_path} (moved #{moved} files, replaced #{replacements} links)"
  total_posts += 1
  total_moved += moved
  total_replacements += replacements
end

puts
puts "Done."
puts "Posts updated: #{total_posts}"
puts "Files moved: #{total_moved}"
puts "Link replacements: #{total_replacements}"

require 'esa'

class Esa::Migration
  attr_reader :client

  def initialize(from:, to:, per_page: 100)
    @client = Esa::Client.new(access_token: ENV.fetch('ESA_ACCESS_TOKEN'))
    @from = from
    @to = to
    @per_page = per_page
    @screen_names = []
  end

  def migration_posts(q: "")
    total_count = posts_total_count_from(q: q)
    ((total_count / @per_page) + 1).times do |i|
      from_posts = @client.posts(q: q, per_page: @per_page, page: i + 1, sort: "created")
      from_posts.body["posts"].each do |post|
        create_post_to(post)
      end
    end
  end

  def migration_stars_watchers(q: "")
    total_count = posts_total_count_from(q: q)

    ((total_count / @per_page) + 1).times do |i|
      @client.current_team = @from
      from_posts = @client.posts(q: q, per_page: @per_page, page: i + 1, sort: "created")
      from_posts.body["posts"].each do |fp|

        next unless fp["star"] || fp["watch"]

        @client.current_team = @to
        to_posts = @client.posts(q: "title:#{fp['name']}", per_page: 1)
        to_posts.body["posts"].each do |tp|
          if fp["star"]
            @client.add_post_star(tp["number"])
            puts "add_post_star: #{tp['full_name']}"
          end
          if fp["watch"]
            @client.add_watch(tp["number"])
            puts "add_watch: #{tp['full_name']}"
          end
        end

      end
    end
  end

  private

  def posts_total_count_from(q: "")
    @client.current_team = @from
    total_count = @client.posts(q: q, per_page: 1).body["total_count"]
    total_count = @per_page if total_count < @per_page
    total_count
  end

  def screen_names_to
    @client.current_team = @to
    total_count = @client.members(per_page: 1).body["total_count"]
    total_count = @per_page if total_count < @per_page

    ((total_count / @per_page) + 1).times do |i|
      member = @client.members(per_page: @per_page, page: i + 1)
      member.body["members"].each do |m|
        @screen_names << m["screen_name"]
      end
    end
  end

  def craete_post_to(post)
    screen_names_to
    screen_name = post["created_by"]["screen_name"]
    screen_name = "esa_bot" unless @screen_names.include?(screen_name)

    params = {
      name: post["name"], body_md: post["body_md"], tags: post["tags"],
      category: post["category"], wip: post["wip"], message: post["message"], user: screen_name
    }
    @client.current_team = @to
    res = @client.create_post(params)
    p res.headers
  end
end

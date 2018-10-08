class Search
  include ActiveModel::Validations
  include ActiveModel::Conversion
  include ActiveModel::AttributeMethods
  extend ActiveModel::Naming

  attr_accessor :q, :order
  attr_accessor :results, :page, :total_results, :per_page
  attr_writer :what

  validates :q, length: { :minimum => 2 }

  def initialize
    @q = ""
    @what = "stories"
    @order = "relevance"

    @page = 1
    @per_page = 20

    @results = []
    @total_results = -1
  end

  def max_matches
    100
  end

  def persisted?
    false
  end

  def to_url_params
    [:q, :what, :order].map {|p| "#{p}=#{CGI.escape(self.send(p).to_s)}" }.join("&amp;")
  end

  def page_count
    total = self.total_results.to_i

    if total == -1 || total > self.max_matches
      total = self.max_matches
    end

    ((total - 1) / self.per_page.to_i) + 1
  end

  def what
    case @what
    when "comments"
      "comments"
    else
      "stories"
    end
  end

  def with_tags(base, tag_scopes)
    base
      .joins({ :taggings => :tag }, :user)
      .where(:tags => { :tag => tag_scopes })
      .having("COUNT(stories.id) = ?", tag_scopes.length)
      .group("stories.id")
  end

  def with_stories_in_domain(base, domain)
    begin
      Rails.logger.info "&&&&&&&&&&&&& base: #{base}, ~~~~~~~~~~ #{domain}"
      reg = Regexp.new("//([^/]*\.)?#{domain}/")
      base.where("`stories`.`url` REGEXP '" +
        ActiveRecord::Base.connection.quote_string(reg.source) + "'")
    rescue RegexpError
      return base
    end
  end

  def with_stories_matching_tags(base, tag_scopes)
    story_ids_matching_tags = with_tags(
      Story.unmerged.where(:is_expired => false), tag_scopes
    ).select(:id).map(&:id)
    base.where(story_id: story_ids_matching_tags)
  end

  def search_for_user!(user)
    self.results = []
    self.total_results = 0

    # extract domain query since it must be done separately
    domain = nil
    tag_scopes = []
    words = self.q.to_s.split(" ").reject {|w|
      if (m = w.match(/^domain:(.+)$/))
        domain = m[1]
      elsif (m = w.match(/^tag:(.+)$/))
        tag_scopes << m[1]
      end
    }.join(" ")

    qwords = ActiveRecord::Base.connection.quote_string(words)
Rails.logger.info "^^^^^^^^^^^^^^ qwords: #{qwords}, domain: #{domain}"
    base = nil

    case self.what
    when "stories"
      base = Story.unmerged.where(:is_expired => false)
      if domain.present?
        Rails.logger.info "$$$$$$$$$$$$$$$$$ isDomain: #{domain}"
        base = with_stories_in_domain(base, domain)
      end

      title_match_sql =  Arel.sql("stories.title like '%#{qwords}%'")
      description_match_sql =
      Arel.sql("stories.description like '%test%'")
      story_cache_match_sql =
      Arel.sql("stories.story_cache like '%test%'")
Rails.logger.info "@@@@@@@@@@@@@@@@@@ begin search"
      if qwords.present?
        Rails.logger.info "@@@@@@@@@@@@ qwords present"
        base.where!(
          "(#{title_match_sql} OR " +
          "#{description_match_sql} OR " +
          "#{story_cache_match_sql})"
        )

        if tag_scopes.present?
          Rails.logger.info "~~~~~~~~~~~~~~~ has tag_scopes "
          self.results = with_tags(base, tag_scopes)
        else
          Rails.logger.info "~~~~~~~~~~~~~~~ has not tag_scopes "
          base = base.includes({ :taggings => :tag }, :user)
          self.results = base.select(
            ["stories.*", title_match_sql, description_match_sql, story_cache_match_sql].join(', ')
          )
        end
        Rails.logger.info "@@@@@@@@@@@@@@@@@@@@ base: #{base}, result: #{self.results}, order: #{self.order}"
      else
        if tag_scopes.present?
          Rails.logger.info "!!!!!!!!!! tag_scopes if"
          self.results = with_tags(base, tag_scopes)
        else
          Rails.logger.info "!!!!!!!!!! tag_scopes else"
          self.results = base.includes({ :taggings => :tag }, :user)
        end
      end

      case self.order
      when "relevance"
        if qwords.present?
          Rails.logger.info "!!!!!!!!!!!!!! order if "
          self.results.order!(Arel.sql("title DESC, " +
                                       "description DESC, " +
                                       "story DESC"))
        else
          Rails.logger.info "!!!!!!!!!!!!!! order desc "
          self.results.order!("stories.created_at DESC")
        end
      when "newest"
        self.results.order!("stories.created_at DESC")
      when "points"
        self.results.order!("#{Story.score_sql} DESC")
      end

    when "comments"
      base = Comment.active
      if domain.present?
        base = with_stories_in_domain(base.joins(:story), domain)
      end
      if tag_scopes.present?
        base = with_stories_matching_tags(base, tag_scopes)
      end
      if qwords.present?
        base = base.where(Arel.sql("MATCH(comment) AGAINST('#{qwords}' IN BOOLEAN MODE)"))
      end
      self.results = base.select(
        "comments.*, " +
        "MATCH(comment) AGAINST('#{qwords}' IN BOOLEAN MODE) AS rel_comment"
      ).includes(:user, :story)

      case self.order
      when "relevance"
        self.results.order!("rel_comment DESC")
      when "newest"
        self.results.order!("created_at DESC")
      when "points"
        self.results.order!("#{Comment.score_sql} DESC")
      end
    end
Rails.logger.info "$$$$$$$$$$$$$$$$$$$$$ after comments. lenght: #{self.results.size}"
    self.total_results = self.results.length

    if self.page > self.page_count
      self.page = self.page_count
    end
    if self.page < 1
      self.page = 1
    end
    Rails.logger.info "#################33 result: "
    self.results = self.results
      .limit(self.per_page)
      .offset((self.page - 1) * self.per_page)
    Rails.logger.info "%%%%%%%%%%%%%%%%%5 begin search, What: #{what}"
    # if a user is logged in, fetch their votes for what's on the page
    if user
      case what
      when "stories"
        votes = Vote.story_votes_by_user_for_story_ids_hash(user.id, self.results.map(&:id))

        self.results.each do |r|
          if votes[r.id]
            r.vote = votes[r.id]
          end
        end

      when "comments"
        votes = Vote.comment_votes_by_user_for_comment_ids_hash(user.id, self.results.map(&:id))

        self.results.each do |r|
          if votes[r.id]
            r.current_vote = votes[r.id]
          end
        end
      end
      Rails.logger.debug "_________________________ size: #{results.size}"
    end

  rescue ActiveRecord::StatementInvalid
    # this is most likely bad boolean chars
    self.results = []
    self.total_results = -1
  end
end

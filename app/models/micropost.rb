class Micropost < ApplicationRecord
  belongs_to :user
  belongs_to :book, optional: true
  has_one_attached :picture
  has_many :likes, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :notifications, dependent: :destroy
  default_scope -> { order(studied_at: :desc) }
  validates :content, length: { maximum: 280 }
  validates :study_amount, numericality: { greater_than_or_equal_to: 1, allow_nil: true }
  validate  :datetime_not_future_time
  validate  :studied_time_non_zero
  validate  :study_time_limit_per_day
  validate  :start_page_greater_than_end_page
  validate  :item_of_page_blank

  def datetime_not_future_time
    errors.add(:studied_at, 'が未来の日時です。') if studied_at > Time.current
  end

  def studied_time_non_zero
    errors.add(:study_time, 'が０分です。') if study_time.zero?
  end

  def study_time_limit_per_day
    from = studied_at.at_beginning_of_day
    to = studied_at.at_end_of_day

    return unless Micropost.where(user_id: user_id).where(studied_at: from...to).sum(:study_time) + study_time >= 1440

    errors.add(:study_time, 'は1日24時間以内にして下さい。')
  end

  def item_of_page_blank
    errors.add(:ページ, 'を入力してください。') if study_amount == 10000
  end

  def start_page_greater_than_end_page
    errors.add(:終了ページ, 'は開始ページより大きい値にして下さい。') if study_amount == 10001
  end

  def create_notification_like!(current_user)
    # すでに「いいね」されているか検索
    temp = Notification.where(['visitor_id = ? and visited_id = ? and micropost_id = ? and action = ? ', current_user.id, user_id, id, 'like'])
    # いいねされていない場合のみ、通知レコードを作成
    return if temp.present?

    notification = current_user.active_notifications.new(
      micropost_id: id,
      visited_id: user_id,
      action: 'like'
    )
    # 自分の投稿に対するいいねの場合は、通知済みとする
    notification.checked = true if notification.visitor_id == notification.visited_id
    notification.save if notification.valid?
  end

  def create_notification_comment!(current_user, comment_id)
    # 自分以外にコメントしている人をすべて取得し、全員に通知を送る
    temp_ids = Comment.select(:user_id).where(micropost_id: id).where.not(user_id: current_user.id).distinct
    temp_ids.each do |temp_id|
      save_notification_comment!(current_user, comment_id, temp_id['user_id'])
    end
    # まだ誰もコメントしていない場合は、投稿者に通知を送る
    save_notification_comment!(current_user, comment_id, user_id) if temp_ids.blank?
  end

  def save_notification_comment!(current_user, comment_id, visited_id)
    # コメントは複数回することが考えられるため、１つの投稿に複数回通知する
    notification = current_user.active_notifications.new(
      micropost_id: id,
      comment_id: comment_id,
      visited_id: visited_id,
      action: 'comment'
    )
    # 自分の投稿に対するコメントの場合は、通知済みとする
    notification.checked = true if notification.visitor_id == notification.visited_id
    notification.save if notification.valid?
  end

  def self.total_study_time
    total = sum(:study_time)
    hours = total / 60
    minutes = total % 60
    [hours, minutes]
  end

  def self.study_time_today
    from = Time.current.at_beginning_of_day
    to = Time.current.at_end_of_day
    from_in_yesterday = Time.current.at_beginning_of_day - 1.day
    to_in_yesterday = Time.current.at_end_of_day - 1.day

    total = where(studied_at: from...to).sum(:study_time)
    total_in_yesterday = where(studied_at: from_in_yesterday...to_in_yesterday).sum(:study_time)
    hours = total / 60
    minutes = total % 60
    [hours, minutes, total, total_in_yesterday]
  end

  def self.study_time_this_week
    from = Time.current.at_beginning_of_week
    to = Time.current.at_end_of_week
    from_in_last_week = Time.current.at_beginning_of_week - 1.week
    to_in_last_week = Time.current.at_end_of_week - 1.week

    total = where(studied_at: from...to).sum(:study_time)
    total_in_last_week = where(studied_at: from_in_last_week...to_in_last_week).sum(:study_time)
    hours = total / 60
    minutes = total % 60
    [hours, minutes, total, total_in_last_week]
  end

  def self.study_time_this_month
    from = Time.current.at_beginning_of_month
    to = Time.current.at_end_of_month
    from_in_last_month = Time.current.at_beginning_of_month - 1.month
    to_in_last_month = Time.current.at_end_of_month - 1.month

    total = where(studied_at: from...to).sum(:study_time)
    total_in_last_month = where(studied_at: from_in_last_month...to_in_last_month).sum(:study_time)
    hours = total / 60
    minutes = total % 60
    [hours, minutes, total, total_in_last_month]
  end

  def self.daily_study_time(n)
    from = Time.current.at_beginning_of_day - n.day
    to = Time.current.at_end_of_day - n.day

    total = where(studied_at: from...to).sum(:study_time)
    hours = total / 60
    minutes = total % 60
    [hours, minutes, total]
  end

  def self.weekly_study_time(n)
    from = Time.current.at_beginning_of_week - n.week
    to = Time.current.at_end_of_week - n.week

    total = where(studied_at: from...to).sum(:study_time)
    hours = total / 60
    minutes = total % 60
    [hours, minutes, total]
  end

  def self.monthly_study_time(n)
    from = Time.current.at_beginning_of_month - n.month
    to = Time.current.at_end_of_month - n.month

    total = where(studied_at: from...to).sum(:study_time)
    hours = total / 60
    minutes = total % 60
    [hours, minutes, total]
  end

  def self.weekly_study_amount(book_id, study_unit, week_target_created_at)
    from = week_target_created_at.at_beginning_of_week
    to = week_target_created_at.at_end_of_week
    posts = where(studied_at: from...to).where(book_id: book_id)

    if study_unit == '時間'
      posts.sum(:study_time)
    else
      posts.where(study_unit: study_unit).sum(:study_amount)
    end
  end
end

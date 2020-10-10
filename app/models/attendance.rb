class Attendance < ApplicationRecord
  # attendanceモデルとuserモデルの関係→1:1の関係を示してる
  belongs_to :user
  validates :worked_on, presence: true
  validates :note, length: { maximum: 50 }
  validates :sceduled_end_time, presence: true, on: :update_overwork_request1
  validates :instructor_confirmation, presence: true, on: :update_overwork_request
  validates :oneday_instructor_confirmation, presence: true, on: :update_one_month
  # 出勤時間が存在しない場合、退勤時間は無効(↓カスタムのバリデーション)
  # validate(sが付かない)→カスタムメソッドをバリデーションとして使う事ができる
  validate :finished_at_is_invalid_without_a_started_at
  # 出勤・退勤時間どちらも存在する時、出勤時間より早い退勤時間は無効にするもの(↓カスタムのバリデーション)
  validate :started_at_than_finished_at_fast_if_invalid
  
  validate :finished_at_is_invalid_without_a_finished_at 
  validate :oneday_instructor_confirmation_only_update_suppression
  # errorsメッセージに追加してる
  # 出勤時間がない、かつ退勤時間が存在する場合→trueとなり処理が実行される
  def finished_at_is_invalid_without_a_started_at
    errors.add(:started_at, "が必要です") if started_at.blank? && finished_at.present?
  end
  
  def started_at_than_finished_at_fast_if_invalid
    if started_at.present? && finished_at.present?
      errors.add(:started_at, "より早い退勤時間は無効です") if started_at > finished_at
    end
  end
  
  # started_atとfinished_at両方そろわないと更新できない(started_atのみでは更新できないようにする)
  def finished_at_is_invalid_without_a_finished_at
    unless Date.current == worked_on
      if started_at.present? && finished_at.blank?
        errors.add(:finished_at, "が必要です")
      end
    end
  end

  # started_atかつfinished_atが無い状態でoneday_instructor_confirmationだけでは勤怠編集を更新できないようにする
  # started_atかfinished_atがどちらかしか存在していない状態で、oneday_instructor_confirmationが存在してる時は上記のバリデーションが働く
  def oneday_instructor_confirmation_only_update_suppression
    if oneday_instructor_confirmation.present?
      if started_at.blank? && finished_at.blank?
        errors.add(:finished_at, "が必要です")
      end
    end
  end
end
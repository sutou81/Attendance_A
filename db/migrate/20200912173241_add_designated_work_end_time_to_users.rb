class AddDesignatedWorkEndTimeToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :designated_work_end_time, :datetime, default: Time.current.change(hour: 17, min: 30, sec: 0)
  end
end

class AddDesignatedWorkStartTimeToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :designated_work_start_time, :datetime, default: Time.current.change(hour: 8, min: 30, sec: 0)
  end
end

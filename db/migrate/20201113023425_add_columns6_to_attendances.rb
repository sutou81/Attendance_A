class AddColumns6ToAttendances < ActiveRecord::Migration[5.2]
  def change
    add_column :attendances, :first_approved_started_at, :datetime
    add_column :attendances, :first_approved_finished_at, :datetime
    add_column :attendances, :approved_update_time, :datetime
  end
end

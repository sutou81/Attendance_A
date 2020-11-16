class AddColumns3ToAttendances < ActiveRecord::Migration[5.2]
  def change
    add_column :attendances, :approved_started_at, :datetime
    add_column :attendances, :approved_finished_at, :datetime
  end
end

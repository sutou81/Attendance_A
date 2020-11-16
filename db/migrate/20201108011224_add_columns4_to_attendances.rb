class AddColumns4ToAttendances < ActiveRecord::Migration[5.2]
  def change
    add_column :attendances, :approved_sceduled_end_time, :datetime
  end
end

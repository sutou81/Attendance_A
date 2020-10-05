class AddColumns1ToAttendances < ActiveRecord::Migration[5.2]
  def change
    add_column :attendances, :overtime_application_status, :string
    add_column :attendances, :attendance_application_status, :string
  end
end

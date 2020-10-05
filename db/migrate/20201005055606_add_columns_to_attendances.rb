class AddColumnsToAttendances < ActiveRecord::Migration[5.2]
  def change
    add_column :attendances, :sceduled_end_time, :datetime
    add_column :attendances, :next_day, :string
    add_column :attendances, :business_content, :string
    add_column :attendances, :instructor_confirmation, :string
  end
end

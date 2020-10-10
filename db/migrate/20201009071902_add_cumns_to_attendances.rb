class AddCumnsToAttendances < ActiveRecord::Migration[5.2]
  def change
    add_column :attendances, :oneday_instructor_confirmation, :string
  end
end

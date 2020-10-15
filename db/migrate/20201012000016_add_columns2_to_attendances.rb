class AddColumns2ToAttendances < ActiveRecord::Migration[5.2]
  def change
    add_column :attendances, :onday_check_box, :string
  end
end

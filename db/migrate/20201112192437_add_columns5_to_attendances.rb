class AddColumns5ToAttendances < ActiveRecord::Migration[5.2]
  def change
    add_column :attendances, :approved_business_content, :string
    add_column :attendances, :approved_note, :string
  end
end

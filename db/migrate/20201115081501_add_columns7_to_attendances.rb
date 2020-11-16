class AddColumns7ToAttendances < ActiveRecord::Migration[5.2]
  def change
    add_column :attendances, :onemonth_instructor_confirmation, :string
    add_column :attendances, :onemonth_application_status, :string, default: "所属長承認： 未申請"
  end
end

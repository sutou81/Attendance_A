class AddEmployeeNumberToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :employee_number, :integer
  end
end

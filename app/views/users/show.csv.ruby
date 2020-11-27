require 'csv'

bom = "\uFEFF"
CSV.generate(bom) do |csv|
  column_names = %w(日付 曜日 出社時間 退社時間 在社時間)
  csv << column_names
  @attendances.each do |day|
    a = day.approved_started_at == nil ? nil : l(day.approved_started_at, format: :time)
    b = day.approved_finished_at == nil ? nil : l(day.approved_finished_at, format: :time)
    column_values = [
      l(day.worked_on, format: :short),
      $days_of_the_week[day.worked_on.wday],
      a,
      b
      
    ]
    csv << column_values
  end
end
# coding: utf-8

User.create!(name: "Sample User",
             email: "sample@email.com",
             password: "password",
             password_confirmation: "password",
             admin: true)

60.times do |n|
  name  = Faker::Name.name
  email = "sample-#{n+1}@email.com"
  num = n+1
  numb = "2#{"%03d" % num}"
  employee_number = numb.to_i
  password = "password"
  User.create!(name: name,
               email: email,
               employee_number: employee_number,
               password: password,
               password_confirmation: password)
end


User.create!(name: "上長A",
  email: "superior-1@email.com",
  employee_number: "1001".to_i,
  password: "password",
  password_confirmation: "password",
  superior: true)


  User.create!(name: "上長B",
    email: "superior-2@email.com",
    employee_number: "1002".to_i,
    password: "password",
    password_confirmation: "password",
    superior: true)
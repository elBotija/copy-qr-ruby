user = User.create!(
  email: 'usuario@ejemplo.com',
  password: '123456',
  terms_of_service: true
)
user.confirm

admin = User.create!(
  email: 'admin@ejemplo.com',
  password: '123456',
  terms_of_service: true,
  admin: true
)
admin.confirm

5.times do
  user.memorials.create!(
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    dob: Faker::Date.between(from: 70.years.ago, to: 20.years.ago),
    dod: Faker::Date.between(from: 19.years.ago, to: 1.day.ago),
    caption: Faker::Lorem.sentence,
    bio: Faker::Lorem.paragraph(random_sentences_to_add: 10)
  )
end

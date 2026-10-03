unless User.exists?(first_name: 'Gijs')
  User.create!(
    first_name: 'Gijs',
    last_name: 'Doedens',
    email: 'vandervoort.gijs@gmail.com',
    password: 'password',
    isadmin: true,
    notify_news: false
  )
end

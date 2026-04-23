unless User.where(first_name: 'Gijs').exists?
  User.create!(
    {
      first_name: 'Gijs',
      last_name: 'Doedens',
      email: 'vandervoort.gijs@gmail.com',
      password: 'password',
      isadmin: true,
      notify_news: false
    },
    as: :admin
  )
end

site :opscode

metadata

%w{
  debian
  nginx
  tknetworks_nginx
  php_fpm
  postgresql
}.each do |c|
  cookbook c, git: "git://github.com/tknetworks-cookbooks/#{c}.git"
end

group :integration do
  cookbook 'apt'

  %w{
    postgresql
    pdns
  }.each do |c|
    cookbook c, git: "git://github.com/tknetworks-cookbooks/#{c}.git"
  end
  cookbook 'minitest-handler'
end

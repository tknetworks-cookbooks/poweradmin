site :opscode

metadata

cookbook "debian", git: "git://github.com/tknetworks-cookbooks/debian.git"
cookbook "pdns", git: "git://github.com/tknetworks-cookbooks/pdns.git"
cookbook "nginx", git: "git://github.com/tknetworks-cookbooks/nginx.git"
cookbook "tknetworks_nginx", git: "git://github.com/tknetworks-cookbooks/tknetworks_nginx.git"
cookbook "php_fpm", git: "git://github.com/tknetworks-cookbooks/php_fpm.git"

group :integration do
  cookbook 'apt'
  cookbook 'minitest-handler'
end

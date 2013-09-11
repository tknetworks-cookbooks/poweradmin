maintainer       "TANABE Ken-ichi"
maintainer_email "nabeken@tknetworks.org"
license          "Apache 2.0"
description      "Installs/Configures poweradmin"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.1"
name             "poweradmin"

%w{freebsd debian}.each do |os|
  supports os
end

%w{debian postgresql pdns php_fpm nginx tknetworks_nginx}.each do |c|
  depends c
end

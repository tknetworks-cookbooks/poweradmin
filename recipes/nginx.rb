#
# Author:: Ken-ichi TANABE (<nabeken@tknetworks.org>)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'chef/mixin/shell_out'
extend Chef::Mixin::ShellOut

include_recipe "nginx"

if node['poweradmin']['use_php_fpm_pool_www']
  include_recipe 'php_fpm::www'
end

nginx_site_conf node['poweradmin']['vhost'] do
  use_php_fpm true, node['poweradmin']['php_fpm_pool']
  use_https   true
  create_htdocs false
end

nginx_site node['poweradmin']['vhost'] do
  enable true
end

template "#{node['nginx']['dir']}/poweradmin.htpasswd" do
  source "poweradmin.htpasswd.erb"
  owner node['nginx']['user']
  group node['nginx']['group']
  mode 0600
  variables :user => node['poweradmin']['htpasswd']['user'],
            :password => node['poweradmin']['htpasswd']['password']
end

template "/var/www/#{node['poweradmin']['vhost']}/nginx.conf" do
  source "nginx.conf.erb"
  owner node['nginx']['user']
  group node['nginx']['group']
  mode 0750
  notifies :restart, "service[nginx]"
end

link "/var/www/#{node['poweradmin']['vhost']}/htdocs" do
  action :create
  to node['poweradmin']['install_dir']
end

directory "#{node['poweradmin']['install_dir']}/install" do
  action :delete
  recursive true
  not_if do
    cmd = shell_out("psql --set ON_ERROR_STOP=yes -U %{db_user} %{db_name} > /dev/null 2>&1" % {
        :db_user => node['pdns']['db_user'],
        :db_name => node['pdns']['db_name'],
      },
      :input => '\d users;',
      :user => 'pdns'
    )
    cmd.exitstatus != 0 || !node['poweradmin']['remove_installer']
  end
end

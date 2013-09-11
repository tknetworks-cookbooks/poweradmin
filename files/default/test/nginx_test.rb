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
require 'minitest/spec'

describe_recipe 'poweradmin::nginx' do
  it 'configures vhost for poweradmin' do
    directory("/var/www/#{node['poweradmin']['vhost']}")
    .must_exist
    .with(:owner, node['nginx']['user'])
    .and(:group, node['nginx']['group'])
    .and(:mode, 0755)
  end

  it 'configures php_fpm using php_fpm_pool resource' do
    available_vhost = "/etc/nginx/sites-available/#{node['poweradmin']['vhost']}"

    link("/etc/nginx/sites-enabled/#{node['poweradmin']['vhost']}")
    .must_exist
    .with(:link_type, :symbolic)
    .and(:to, available_vhost)

    file(available_vhost)
    .must_include("unix:/var/run/php5-fpm-www.sock")
    .and(:mode, 0644)
  end

  it 'creates nginx.conf' do
    file("/var/www/#{node['poweradmin']['vhost']}/nginx.conf")
    .must_include "auth_basic_user_file #{node['nginx']['dir']}/poweradmin.htpasswd;"
  end

  it 'creates htpasswd file' do
    file("#{node['nginx']['dir']}/poweradmin.htpasswd")
    .must_include("#{node['poweradmin']['htpasswd']['user']}:#{node['poweradmin']['htpasswd']['password']}:Poweradmin")
    .with(:owner, node['nginx']['user'])
    .and(:group, node['nginx']['group'])
    .and(:mode, 0600)
  end

  it 'links htdocs to app directory' do
    link("/var/www/#{node['poweradmin']['vhost']}/htdocs")
    .must_exist
    .with(:link_type, :symbolic)
    .and(:to, node['poweradmin']['install_dir'])
  end

  it 'serves poweradmin page' do
    assert_sh("content=$(wget --no-check-certificate --header='Host: %{vhost}' --http-user=%{user} --http-password=%{password} -O- https://127.0.0.1/ 2> /dev/null)
echo \"${content}\" | grep poweradmin" % {
      :vhost => node['poweradmin']['vhost'],
      :user => node['poweradmin']['htpasswd']['user'],
      :password => node['poweradmin']['htpasswd']['raw_password']
    })
  end
end

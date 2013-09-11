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
node['poweradmin']['packages'].each do |pkg|
  package pkg do
    action :install
    source "ports" if node['platform'] == "freebsd"
  end
end

# For some systems which does not have /var/www by default
directory "/var/www" do
  action :create
  user node['nginx']['user']
  group node['nginx']['group']
  mode 0755
end

git node['poweradmin']['install_dir'] do
  user node['nginx']['user']
  group node['nginx']['group']
  repository node['poweradmin']['git']['repository']
  reference node['poweradmin']['git']['tag']
  action :sync
  not_if do
    ::File.exists?(node['poweradmin']['install_dir'])
  end
end

template "#{node['poweradmin']['install_dir']}/inc/config.inc.php" do
  owner node['nginx']['user']
  group node['nginx']['group']
  mode 0640
  source "config.inc.php.erb"
end

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
require 'spec_helper'

describe 'poweradmin::default' do
  include_context 'debian'

  let (:chef_run) {
    ChefSpec::ChefRunner.new() do |node|
      set_node(node)
    end
  }

  before do
    chef_run.node.automatic_attrs['poweradmin']['vhost'] = 'ns.example.org'
    Chef::EncryptedDataBagItem.stub(:load).with('certs', 'ns_example_org').and_return(
      {
        'id' => 'ns_example_org',
        'cert' => "CERT",
        'key1' => 'key1',
        'key2' => 'key2'
      }
    )
  end

  context 'using php_fpm::www' do
    before do
      chef_run.converge('poweradmin::nginx')
    end

    it 'should include nginx recipe' do
      expect(chef_run).to include_recipe 'nginx'
    end

    it 'should include php_fpm::www recipe' do
      expect(chef_run).to include_recipe 'php_fpm::www'
    end

    it 'should create htpasswd file' do
      expect(chef_run)
      .to create_file_with_content "#{chef_run.node['nginx']['dir']}/poweradmin.htpasswd", "poweradmin:secret:Poweradmin"
    end

    it 'should create nginx.conf' do
      expect(chef_run)
      .to create_file_with_content "/var/www/#{chef_run.node['poweradmin']['vhost']}/nginx.conf",
                                   "auth_basic_user_file #{chef_run.node['nginx']['dir']}/poweradmin.htpasswd;"
    end

    it 'should link htdocs to app directory' do
      expect(chef_run)
      .to create_link("/var/www/#{chef_run.node['poweradmin']['vhost']}/htdocs")
      .with(:to => chef_run.node['poweradmin']['install_dir'])
    end

  end

  context 'using custom php_fpm_pool resource' do
    before do
      chef_run.node.set['poweradmin']['use_php_fpm_pool_www'] = false
      chef_run.converge('poweradmin::nginx')
    end

    it 'should not include php_fpm::www recipe' do
      expect(chef_run).not_to include_recipe 'php_fpm::www'
    end
  end
end

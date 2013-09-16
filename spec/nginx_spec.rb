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
    ChefSpec::ChefRunner.new(:evaluate_guards => true) do |node|
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
    Chef::Resource.any_instance.stub(:shell_out).and_return(
      double('shell_out').tap { |m| m.stub(:exitstatus).and_return(3) }
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
      .to create_file_with_content("#{chef_run.node['nginx']['dir']}/poweradmin.htpasswd", "poweradmin:secret:Poweradmin")

      expect(chef_run)
      .to create_file("#{chef_run.node['nginx']['dir']}/poweradmin.htpasswd")
      .with(:owner => chef_run.node['nginx']['user'],
            :group => chef_run.node['nginx']['group'],
            :mode => 0600)
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

  shared_examples_for 'remove_installer == false' do
    it 'should not remove installer' do
      chef_run.converge('poweradmin::nginx')
      expect(chef_run)
      .not_to delete_directory("#{chef_run.node['poweradmin']['install_dir']}/install")
      .with(:recursive => true)
    end
  end

  shared_examples_for 'remove_installer == true' do
    it 'should remove installer' do
      chef_run.converge('poweradmin::nginx')
      expect(chef_run)
      .to delete_directory("#{chef_run.node['poweradmin']['install_dir']}/install")
      .with(:recursive => true)
    end
  end

  describe 'when users table found' do
    before do
      Chef::Resource.any_instance.stub(:shell_out).and_return(double(:exitstatus => 0))
    end

    context 'and actualy set remove_installer == false' do
      before do
        chef_run.node.set['poweradmin']['remove_installer'] = false
      end

      it_behaves_like 'remove_installer == false'
    end

    context 'and actualy set remove_installer == true' do
      before do
        chef_run.node.set['poweradmin']['remove_installer'] = true
      end

      it_behaves_like 'remove_installer == true'
    end
  end

  describe 'when no users table found' do
    before do
      Chef::Resource.any_instance.stub(:shell_out).and_return(double(:exitstatus => 3))
    end

    context 'and actualy set remove_installer == false' do
      before do
        chef_run.node.set['poweradmin']['remove_installer'] = false
      end

      it_behaves_like 'remove_installer == false'
    end

    context 'and actualy set remove_installer == true' do
      before do
        chef_run.node.set['poweradmin']['remove_installer'] = true
      end

      it_behaves_like 'remove_installer == false'
    end
  end
end

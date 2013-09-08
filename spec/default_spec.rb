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
    chef_run.converge('poweradmin::default')
  end

  it "should install poweradmin's deps" do
    chef_run.node['poweradmin']['packages'].each do |pkg|
      expect(chef_run).to install_package pkg
    end
  end

  it "should install poweradmin from git repository" do
    ::File.stub(:exists?).and_call_original
    ::File.stub(:exists?).with(chef_run.node['poweradmin']['install_dir']).and_return(false)
    git = chef_run.git(chef_run.node['poweradmin']['install_dir'])
    expect(git.action).to include(:sync)
    expect(git.reference).to eq(chef_run.node['poweradmin']['git']['tag'])
    expect(git.user).to eq('www-data')
    expect(git.group).to eq('www-data')
    expect(git.repository).to eq(chef_run.node['poweradmin']['git']['repository'])
  end

  it "should create config.inc.php" do
    conf = "#{chef_run.node['poweradmin']['install_dir']}/inc/config.inc.php"
    expect(chef_run).to create_file_with_content conf, %Q[$db_host                = '127.0.0.1';]
    expect(chef_run).to create_file_with_content conf, %Q[$dns_hostmaster         = 'hostmaster.example.com';]
  end
end

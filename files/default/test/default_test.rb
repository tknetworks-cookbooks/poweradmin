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

describe_recipe 'poweradmin::default' do
  it "installs poweradmin's deps" do
    node['poweradmin']['packages'].each do |pkg|
      package(pkg).must_be_installed
    end
  end

  it "installs poweradmin from git repository with specified version" do
    dir = directory("#{node['poweradmin']['install_dir']}/.git")
    dir.must_exist
    dir.must_have(:mode, 0755)
    dir.must_have(:owner, node['nginx']['user'])
    dir.must_have(:group, node['nginx']['group'])

    assert_sh("""cd #{node['poweradmin']['install_dir']}
tag=\"$(git show-ref -d --tags #{node['poweradmin']['git']['tag']} | tail -n1 | cut -d' ' -f1)\"
head=\"$(git show-ref -d --head HEAD | head -n1 | cut -d' ' -f1)\"
[ \"${tag}\" = \"${head}\" ]
""")
  end

  it "creates config.inc.php" do
    conf = file("#{node['poweradmin']['install_dir']}/inc/config.inc.php")
    conf.must_exist
    conf.must_have(:mode, 0640)
    conf.must_include %Q[$db_host                = '127.0.0.1';]
    conf.must_include %Q[$dns_hostmaster         = 'hostmaster.example.org';]
  end
end

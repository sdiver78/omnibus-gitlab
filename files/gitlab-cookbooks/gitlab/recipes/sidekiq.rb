#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2014 GitLab.com
# License:: Apache License, Version 2.0
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
account_helper = AccountHelper.new(node)

sidekiq_service 'sidekiq' do
  rails_app 'gitlab-rails'
  user account_helper.gitlab_user
  group account_helper.gitlab_group
end

if node['consul']['enable'] && node['consul']['monitoring_service_discovery']
  consul_service 'sidekiq' do
    ip_address node['gitlab']['sidekiq']['listen_address']
    port node['gitlab']['sidekiq']['listen_port']
  end
end

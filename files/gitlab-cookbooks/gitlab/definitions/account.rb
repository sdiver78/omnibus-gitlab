#
# Copyright:: Copyright (c) 2015 GitLab B.V.
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

define :account, action: nil, username: nil, uid: nil, ugid: nil, groupname: nil, gid: nil, shell: nil, home: nil, system: true, append_to_group: false, group_members: [], user_supports: {} do

  groupname = params[:groupname]
  username = params[:username]

  if groupname
    group groupname do
      gid params[:gid]
      system params[:system]
      if params[:append_to_group]
        append true
        members params[:group_members]
      end
    end
  end

  if username
    user username do
      shell params[:shell]
      home params[:home]
      uid params[:uid]
      gid params[:ugid]
      system params[:system]
      supports params[:user_supports]
    end
  end
end

require 'chef_helper'

describe 'consul_service' do
  let(:runner) do
    ChefSpec::SoloRunner.new(step_into: %w(consul_service))
  end

  context 'create' do
    before do
      runner.node.automatic['ipaddress'] = '10.1.1.1'
    end

    context 'with service address and port properties' do
      let(:chef_run) { runner.converge('test_consul::consul_service_address_port') }

      it 'creates the Consul service file' do
        expect(chef_run).to render_file('/var/opt/gitlab/consul/config.d/node-exporter-service.json')
          .with_content('{"service":{"name":"node-exporter","address":"10.1.1.1","port":1234}}')
      end
    end

    context 'with a socket property' do
      let(:chef_run) { runner.converge('test_consul::consul_service_socket') }

      it 'creates the Consul service file' do
        expect(chef_run).to render_file('/var/opt/gitlab/consul/config.d/node-exporter-service.json')
                              .with_content('{"service":{"name":"node-exporter","address":"10.1.1.1","port":5678}}')
      end
    end
  end

  context 'delete' do
    let(:chef_run) { runner.converge('test_consul::consul_service_delete') }

    it 'deletes the Consul service file' do
      expect(chef_run).to delete_file('/var/opt/gitlab/consul/config.d/delete-me-service.json')
    end
  end
end

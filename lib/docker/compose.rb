# frozen_string_literal: true

require 'yaml'

class Compose
  def self.create(workspace, containers)
    File.write("#{workspace}/docker-compose.yml", template(containers).to_yaml)
  end

  def self.template(containers)
    template = { 'version' => '3.1' }
    template['services'] = services(containers)
    template
  end

  def self.services(containers)
    template = {}
    containers.each do |container|
      template[container['name']] = {}
      template[container['name']]['image'] = container['image']
      template[container['name']]['ports'] = container['ports'] unless container['ports'].empty?
      template[container['name']]['deploy'] = {
        'mode' => 'replicated',
        'replicas' => 1,
        'restart_policy' => {
          'condition' => 'on-failure'
        },
        'placement' => {
          'constraints' => [
            'node.role == worker'
          ]
        },
        'resources' => {
          'limits' => {
            'memory' => '512M'
          },
          'reservations' => {
            'memory' => '512M'
          }
        }
      }
    end
    template
  end
end

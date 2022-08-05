require 'yaml'

class Compose
  def self.create(file, containers)
    File.write(file, template(containers).to_yaml)
  end

  def self.template(containers)
    template = { version: '3.1' }
    template['services'] = services(containers)
    template
  end

  def self.services(containers)
    template = {}
    containers.each do |container|
      template[container['name']] = {}
      template[container['name']]['image'] = container['image']
      template[container['name']]['deploy'] = {
        mode: 'replicated',
        replicas: 1,
        restart_policy: {
          condition: 'on-failure'
        },
        placement: {
          constraints: [
            'node.role == worker'
          ]
        },
        resources: {
          limits: {
            memory: '512M'
          },
          reservations: {
            memory: '512M'
          }
        }
      }
    end
    template
  end
end

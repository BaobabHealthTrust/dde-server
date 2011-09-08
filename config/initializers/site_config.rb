SITE_CONFIG = YAML.load(Rails.root.join('config/site_config.yml').read)[Rails.env].with_indifferent_access.freeze

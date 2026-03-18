# frozen_string_literal: true

module CloudLayerio
  module Options
    # Common options shared across all conversion endpoints.
    class BaseOptions
      include OptionBase

      field :name
      field :timeout
      field :delay
      field :filename
      field :inline
      field :async
      field :storage
      field :webhook
      field :api_ver, json_key: 'apiVer'
      field :project_id, json_key: 'projectId'
    end

    # References a saved storage configuration by ID.
    class StorageRequestOptions
      include OptionBase

      field :id
    end

    # Parameters for creating/updating a storage configuration.
    class StorageParams
      include OptionBase

      field :title
      field :region
      field :access_key_id, json_key: 'accessKeyId'
      field :secret_access_key, json_key: 'secretAccessKey'
      field :bucket
      field :endpoint
    end

    # Query parameters for listing public templates.
    class ListTemplatesOptions
      include OptionBase

      field :type
      field :category
      field :tags
      field :expand
    end

    # Options for the wait_for_job polling utility.
    class WaitForJobOptions
      include OptionBase

      field :interval
      field :max_wait, json_key: 'maxWait'

      def initialize(interval: 5, max_wait: 300, **kwargs)
        super
        raise ValidationError, 'interval must be >= 2 seconds' if @interval < 2
      end
    end
  end
end

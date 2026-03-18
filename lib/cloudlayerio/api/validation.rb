# frozen_string_literal: true

module CloudLayerio
  module Api
    # Client-side validation for conversion options.
    # Mirrors server validation for fast feedback.
    module Validation
      module_function

      def validate_base_options(opts)
        validate_timeout(opts[:timeout])
        validate_async_storage(opts[:async], opts[:storage])
        validate_webhook(opts[:webhook])
        validate_storage_id(opts[:storage])
      end

      def validate_url_options(opts)
        validate_base_options(opts)
        validate_url_or_batch(opts[:url], opts[:batch])
        validate_authentication(opts[:authentication])
        validate_cookies(opts[:cookies])
      end

      def validate_html_options(opts)
        validate_base_options(opts)
        return unless opts[:html].nil? || opts[:html].to_s.empty?

        raise ValidationError, 'html is required and must be a non-empty string'
      end

      def validate_template_options(opts)
        validate_base_options(opts)
        has_id = opts[:template_id] && !opts[:template_id].to_s.empty?
        has_tmpl = opts[:template] && !opts[:template].to_s.empty?
        raise ValidationError, 'template_id or template is required' unless has_id || has_tmpl
        raise ValidationError, 'template_id and template are mutually exclusive' if has_id && has_tmpl
      end

      def validate_file_options(opts)
        validate_base_options(opts)
        raise ValidationError, 'file is required' if opts[:file].nil?
      end

      def validate_image_options(opts)
        quality = opts[:quality]
        return if quality.nil?
        return if quality.is_a?(Numeric) && quality.between?(0, 100)

        raise ValidationError, "quality must be 0-100 (got #{quality})"
      end

      # --- Individual validators ---

      def validate_timeout(timeout)
        return if timeout.nil?
        return if timeout.is_a?(Numeric) && timeout >= 1000

        raise ValidationError, "timeout must be >= 1000ms (got #{timeout})"
      end

      def validate_async_storage(async_val, storage)
        return unless async_val

        raise ValidationError, 'async: true requires storage to be set' unless storage
      end

      def validate_webhook(webhook)
        return if webhook.nil?

        raise ValidationError, 'webhook must be an HTTPS URL' unless webhook.to_s.start_with?('https://')
      end

      def validate_storage_id(storage)
        return unless storage.is_a?(Hash)

        id = storage[:id] || storage['id']
        raise ValidationError, 'storage.id must be a non-empty string' if id.nil? || id.to_s.empty?
      end

      def validate_url_or_batch(url, batch)
        has_url = present?(url)
        has_batch = batch && batch_urls(batch).any?

        raise ValidationError, 'url or batch.urls is required' unless has_url || has_batch
        raise ValidationError, 'url and batch are mutually exclusive' if has_url && has_batch

        validate_batch_urls(batch) if has_batch
      end

      def present?(value)
        value && !value.to_s.empty?
      end

      def validate_batch_urls(batch)
        urls = batch_urls(batch)
        raise ValidationError, 'batch.urls must not be empty' if urls.empty?
        raise ValidationError, "batch.urls max 20 items (got #{urls.length})" if urls.length > 20
      end

      def validate_authentication(auth)
        return if auth.nil?

        username = extract_field(auth, :username)
        password = extract_field(auth, :password)
        return unless username.to_s.empty? || password.to_s.empty?

        raise ValidationError, 'authentication requires both username and password'
      end

      def validate_cookies(cookies)
        return if cookies.nil? || cookies.empty?

        cookies.each_with_index do |cookie, i|
          name = extract_field(cookie, :name)
          value = extract_field(cookie, :value)
          next unless name.to_s.empty? || value.to_s.empty?

          raise ValidationError, "cookie[#{i}] requires non-empty name and value"
        end
      end

      def extract_field(obj, field)
        if obj.respond_to?(field)
          obj.public_send(field)
        else
          obj[field] || obj[field.to_s]
        end
      end

      def batch_urls(batch)
        return [] if batch.nil?

        if batch.respond_to?(:urls)
          batch.urls || []
        else
          batch[:urls] || batch['urls'] || []
        end
      end

      private_class_method :validate_timeout, :validate_async_storage, :validate_webhook,
                           :validate_storage_id, :validate_url_or_batch, :validate_batch_urls,
                           :validate_authentication, :validate_cookies, :extract_field,
                           :batch_urls, :present?
    end
  end
end

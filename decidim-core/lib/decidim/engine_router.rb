# frozen_string_literal: true

module Decidim
  #
  # This class is responsible for sending route helper methods to the correct
  # mounted engine. To do that, it needs to know the name of the mounted helper
  # for the engine, and the contextual parameters to identify the mount point
  # for it, which are added to the parameters passed to the route helper.
  #
  class EngineRouter
    include Rails.application.routes.mounted_helpers

    # Instantiates a router to the frontend engine for an object.
    #
    # @param target [#mounted_engine, #mounted_params] Object to be routed
    #
    # @return [EngineRouter] The new engine router
    def self.main_proxy(target)
      new(target.mounted_engine, target.mounted_params)
    end

    # Instantiates a router to the backend engine for an object.
    #
    # @param target [#mounted_admin_engine, #mounted_params] Object to be routed
    #
    # @return [EngineRouter] The new engine router
    def self.admin_proxy(target)
      new(target.mounted_admin_engine, target.mounted_params)
    end

    def initialize(engine, default_url_options)
      @engine = engine
      @default_url_options = default_url_options
    end

    def default_url_options
      @default_url_options.reverse_merge(configured_default_url_options)
    end

    def respond_to_missing?(method_name, include_private = false)
      route_helper?(method_name) || super
    end

    def method_missing(method_name, *)
      return super unless route_helper?(method_name)

      send(@engine).send(method_name, *)
    end

    private

    def route_helper?(method_name)
      method_name.to_s.match?(/_(url|path)$/)
    end

    def configured_default_url_options
      @configured_default_url_options ||=
        ActionMailer::Base.default_url_options.presence ||
        UrlOptionResolver.new.options
    end
  end
end

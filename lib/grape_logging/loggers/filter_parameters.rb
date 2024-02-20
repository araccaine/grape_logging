module GrapeLogging
  module Loggers
    class FilterParameters < GrapeLogging::Loggers::Base
      AD_PARAMS = 'action_dispatch.request.parameters'.freeze
      # Key to access grape's route_param in request.env
      # See https://github.com/aserafin/grape_logging/issues/27#issuecomment-215333778
      API_PARAMS = 'api.endpoint'.freeze

      def initialize(filter_parameters = nil, replacement = nil, exceptions = %w(controller action format))
        @filter_parameters = filter_parameters || (defined?(::Rails.application) ? ::Rails.application.config.filter_parameters : [])
        @replacement = replacement || '[FILTERED]'
        @exceptions = exceptions
      end

      def parameters(request, _)
        { params: safe_parameters(request) }
      end

      private

      def parameter_filter
        @parameter_filter ||= ParameterFilter.new(@replacement, @filter_parameters)
      end

      def safe_parameters(request)
        request.params.merge!(api_route_params(request)) if api_route_params(request)&.any?
        request.params.merge!(rails_params(request))     if rails_params(request)&.any?

        clean_parameters(request.params)
      end

      def clean_parameters(parameters)
        parameter_filter.filter(parameters).reject{ |key, _value| @exceptions.include?(key) }
      end

      # Extract grape route_param parameters
      def api_route_params(request)
        return unless request.env

        request.env[API_PARAMS]&.params&.to_h
      end

      # Extract action dispatch parameters
      def rails_params(request)
        return unless request.env

        request.env[AD_PARAMS]
      end
    end
  end
end

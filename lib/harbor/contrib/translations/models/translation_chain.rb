require 'i18n'

module Harbor
  module Contrib
    module Translations
      class TranslationChain

        @@backends = []

        def initialize(*backends)
          @@backends = backends
        end

        def add_backend(backend)
          @@backends.push backend if backend
        end

        def backends
          @@backends ||= {}
        end

        # Returns 'key' if the translation is not present in any of the backends.
        def get(locale, key)
          return nil if !locale || !key

          # Populate backends which do not have the translation from a backend that does
          unfilled = backends.select do |backend|
            !exists_in_backend?(backend, locale, key)
          end
          filled = (backends - unfilled).first

          if unfilled && filled
            value = filled.translate(locale, key)
            unfilled.each do |backend|
              backend.store_translations(locale, {key => value}, :escape => false)
            end

            value
          else
            key
          end
        end

        def put(locale, key, value)
          backends.first.store_translations(locale, {key => value}, :escape => false)
        end

        def keys
          backends.first.store.keys
        end

        def exists?(locale, key)
          backends.each do |backend|
            return true if exists_in_backend?(backend, locale, key)
          end

          false
        end

        def exists_in_backend?(backend, locale, key)
          backend.send(:lookup, locale, key).present?
        end
        
      end
    end
  end
end
require 'i18n'
require 'harbor/contrib/translations/key_value_mixin'

module Harbor
  module Contrib
    module Translations
      class TranslationChain

        class I18n::Backend::KeyValue
          include KeyValueMixin
        end

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
          filled = (backends - unfilled).last

          if unfilled && filled
            value = filled.translate(locale, key)
            unfilled.each do |backend|
              backend.store_translations(locale, {key => value}, :escape => false)
            end

            value
          elsif unfilled && !filled
            # All backends are empty. Populate using 'key' as both the key and
            # the value.
            unfilled.each do |backend|
              backend.store_translations(locale, {key => key}, :escape => false)
            end

            key
          else
            key
          end
        end

        def put(locale, key, value)
          backends.each do |backend|
            backend.store_translations(locale, {key => value}, :escape => false)
          end
        end

        def keys(locale = nil)
          backends.last.keys(locale)
        end

        def lookup(locale, key)
          backends.last.lookup(locale, key)
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

require "pathname"
require Pathname(__FILE__).dirname + "helper"

class LocaleClassTest < Test::Unit::TestCase
  def setup
    en_au = Harbor::Locale.new
    en_au.culture_code        = 'en-AU'
    en_au.time_formats        = {:long => "%d/%m/%Y %h:%m:%s", :default => "%h:%m:%s"}
    en_au.date_formats        = {:default => '%d/%m/%Y'}
    en_au.decimal_formats     = {:default => "%8.2f", :currency => "$%8.2f"}
    en_au.wday_names          = [nil, 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
    en_au.wday_abbrs          = [nil, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat']
    en_au.month_names         = [nil, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'Steptember', 'October', 'November', 'December']
    en_au.month_abbrs         = [nil, 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'June', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    en_au.meridian_indicator = {"AM" => "AM", "PM" => "PM"}

    Harbor::Locale.register(en_au)
  end
  
  def test_locale_returns_default_locale_when_none_specified
    assert_equal Harbor::Locale.default, get("/", {'HTTP_ACCEPT_LANGUAGE' => nil}).locale
  end

  def test_locales_returns_default_locale_when_blank_specified
    assert_equal Harbor::Locale.default, get("/", {'HTTP_ACCEPT_LANGUAGE' => ''}).locale
  end

  
  def test_locales_returns_default_locale_when_invalid_locale_string_provided
    assert_equal Harbor::Locale.default, get("/", {'HTTP_ACCEPT_LANGUAGE' => 'ru'}).locale
  end
    
  def test_parse_should_sort_by_q_before_picking
    assert_equal Harbor::Locale['en-AU'], get("/", {'HTTP_ACCEPT_LANGUAGE' => 'en-AU,en-US;q=0.9'}).locale
    assert_equal Harbor::Locale['en-AU'], get("/", {'HTTP_ACCEPT_LANGUAGE' => 'en-AU;q=0.9,en-US;q=0.8'}).locale
    assert_equal Harbor::Locale['en-US'], get("/", {'HTTP_ACCEPT_LANGUAGE' => 'en-AU;q=0.8,en-US;q=0.9'}).locale
  end
  
  def get(path, options = {})
    request(path, "GET", options)
  end

  def request(path, method, options)
    Harbor::Request.new(Class.new, Rack::MockRequest.env_for(path, options.merge(:method => method)))
  end
  
end

class LocaleTest < Test::Unit::TestCase
  
  def setup
    @locale = Harbor::Locale.new
    @locale.culture_code        = 'en-CA'
    @locale.time_formats        = {:long => "%m/%d/%Y %I:%M %p", :default => "%I:%M %p"}
    @locale.date_formats        = {:default => '%m/%d/%Y'}
    @locale.decimal_formats     = {:default => "%s", :currency => "$%01.2f", :percent => "%s%%"}
    @locale.wday_names          = [nil, 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
    @locale.wday_abbrs          = [nil, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat']
    @locale.month_names         = [nil, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'Steptember', 'October', 'November', 'December']
    @locale.month_abbrs         = [nil, 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'June', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    @locale.meridian_indicator = {"AM" => "AM", "PM" => "PM"}

    Harbor::Locale.register(@locale)
  end
  
  def breakdown
    Harbor::Locale.flush!
  end
  
  # ======= testing the giant hash in the sky
  def test_setting_a_replacement
    @locale.set('organization', 'organisation')
    assert_equal 'organisation', @locale.entries['organization']
  end
  
  def test_getting_a_replacement
    @locale.entries['organization'] = 'organisation'
    assert_equal 'organisation', @locale.get('organization')
  end
  
  def test_loading_replacements_from_hash
    @locale.load({'organizations' => 'organisations', 'organization' => 'organisation'})
    assert_equal 'organisation', @locale.get('organization')
    assert_equal 'organisations', @locale.get('organizations')
  end
  # ========
  
  
  def test_returns_untranslated_string_key_when_no_translation_specified
    assert_equal w('organization'), @locale.translate('organization')
  end
  
  def test_returns_translation_when_specified
    @locale.set('organization', 'organisation')
    assert_equal w('organisation', true), @locale.translate('organization')
  end
  
  def test_returns_translated_string_when_path_specified
    @locale.set("account/organization", 'organisation')
    assert_equal w('organisation', true), @locale.translate('account/organization')
  end
  
  def test_returns_translation_by_shifting_paths
    @locale.set('organization', 'organisation')
    assert_equal w('organisation', true), @locale.translate('account/organization')
  end
  
  def test_returns_just_the_key_portion_of_a_path_when_searching_fails
    assert_equal w('organization', false), @locale.translate('account/organization')
  end
  
  def test_interpolates_named_positions
    assert_equal w('12 records'), @locale.translate('{{count}} records', {:count => 12})
    assert_equal w('12 records, 24 pages'), @locale.translate('{{count}} records, {{total}} pages', {:count => 12, :total => 24})
    
    @locale.set("{{count}} records", "ze {{count}} recordos")
    assert_equal w('ze 12 recordos', true), @locale.translate('{{count}} records', {:count => 12})
    
    assert_equal w('12 records, 24 pages, 12 records'), @locale.translate('{{count}} records, {{total}} pages, {{count}} records', {:count => 12, :total => 24})
  end
  
  def test_localize_values_before_interpolating_named_positions
    assert_equal w("12.2 is a decimal"), @locale.translate('{{decimal}} is a decimal', :decimal => 12.2)
    assert_equal w("04/15/2010 is d-day"), @locale.translate('{{date}} is d-day', :date => Date.civil(2010, 4, 15))
    assert_equal w("11:00 PM is t-time"), @locale.translate('{{time}} is t-time', :time => Time.at(946702800))
  end
  
  def test_localizes_decimals
    assert_equal '10', @locale.localize(10)
    assert_equal '10.0', @locale.localize(10.0)
    assert_equal "$10.00", @locale.localize(10.0, :currency)
    assert_equal "10.0%", @locale.localize(10.0, :percent)
  end
  
  def test_localizes_dates
    date = Date.civil(2010, 4, 15)
    date_localization = date.strftime(@locale.date_formats[:default])
    
    assert_equal date_localization, @locale.localize(date)
  end
  
  def test_localizes_times
    time = Time.at(946702800) # 1999-12-31 23:00:00
    default_localization = "11:00 PM"
    long_localization = "12/31/1999 11:00 PM"
    
    assert_equal @locale.localize(time), default_localization
    assert_equal @locale.localize(time, :long), long_localization
  end
  
  def w(string, translated = false)
    Harbor::Locale::LocalizedString.new(string, translated)
  end
  
end
  
class LocalizedStringTest < Test::Unit::TestCase
  def test_translated
    assert Harbor::Locale::LocalizedString.new("test", true).translated?
    assert !Harbor::Locale::LocalizedString.new("test").translated?
  end
  
  def test_to_string
    assert_equal "test", Harbor::Locale::LocalizedString.new("test", true).to_s
    assert_equal "<span class='untranslated'>test</span>", Harbor::Locale::LocalizedString.new("test").to_s
  end
end

class LocalizedDateTest < Test::Unit::TestCase
  
  def setup
    @locale = Harbor::Locale.new
    @locale.culture_code        = 'fr-FR'
    @locale.time_formats        = {:long => "%m/%d/%Y %I:%M %p", :default => "%I:%M %p"}
    @locale.date_formats        = {:default => '%m/%d/%Y', :proper => "%B %d %Y", :long => "%A, %B %d %Y"}
    @locale.decimal_formats     = {:default => "%s", :currency => "$%01.2f", :percent => "%s%%"}
    @locale.wday_names          = [nil, 'Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi']
    @locale.wday_abbrs          = [nil, 'Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam']
    @locale.month_names         = [nil, 'Janvier', 'f&eacute;vrier', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Ao&ucirc;t', 'Septembre', 'Octobre', 'Novembre', 'D&eacute;cembre']
    @locale.month_abbrs         = [nil, 'Jan', 'F&eacute;v', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Ao&ucirc;', 'Sep', 'Oct', 'Nov', 'D&eacute;c']
    @locale.meridian_indicator = {"AM" => "du matin", "PM" => "du soir"}

    Harbor::Locale.register(@locale)
    
    @unlocalized_date = Date.parse("1999-12-31") # 1999-12-31
  end
  
  def test_strftime
    localized_date = Harbor::Locale::LocalizedDate.new(@unlocalized_date, @locale)
    assert_equal localized_date.strftime("%B"), "D&eacute;cembre"
    assert_equal localized_date.strftime("%a"), "Jeu"
    assert_equal localized_date.strftime("%A"), "Jeudi"
    assert_equal localized_date.strftime("%b"), "D&eacute;c"
    assert_equal localized_date.strftime("%B"), "D&eacute;cembre"

    assert_equal localized_date.strftime(@locale.date_formats[:default]), "12/31/1999"
  end
end

class LocalizedTimeTest < Test::Unit::TestCase
  
  def setup
    @locale = Harbor::Locale.new
    @locale.culture_code        = 'fr-FR'
    @locale.time_formats        = {:long => "%m/%d/%Y %I:%M %p", :default => "%I:%M %p"}
    @locale.date_formats        = {:default => '%m/%d/%Y', :proper => "%B %d %Y", :long => "%A, %B %d %Y"}
    @locale.decimal_formats     = {:default => "%s", :currency => "$%01.2f", :percent => "%s%%"}
    @locale.wday_names          = [nil, 'Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi']
    @locale.wday_abbrs          = [nil, 'Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam']
    @locale.month_names         = [nil, 'Janvier', 'f&eacute;vrier', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Ao&ucirc;t', 'Septembre', 'Octobre', 'Novembre', 'D&eacute;cembre']
    @locale.month_abbrs         = [nil, 'Jan', 'F&eacute;v', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Ao&ucirc;', 'Sep', 'Oct', 'Nov', 'D&eacute;c']
    @locale.meridian_indicator = {"AM" => "du matin", "PM" => "du soir"}

    Harbor::Locale.register(@locale)
    
    @unlocalized_time = Time.at(946702800) # 1999-12-31 23:00:00
  end
  
  def test_strftime
    localized_time = Harbor::Locale::LocalizedTime.new(@unlocalized_time, @locale)
    assert_equal localized_time.strftime("%p"), "du soir"

    assert_equal localized_time.strftime(@locale.time_formats[:default]), "11:00 du soir"
    assert_equal localized_time.strftime(@locale.time_formats[:long]), "12/31/1999 11:00 du soir"
  end
end

class LocalizedDateTimeTest < Test::Unit::TestCase
  
  def setup
    @locale = Harbor::Locale.new
    @locale.culture_code        = 'fr-FR'
    @locale.time_formats        = {:long => "%m/%d/%Y %I:%M %p", :default => "%I:%M %p"}
    @locale.date_formats        = {:default => '%m/%d/%Y', :proper => "%B %d %Y", :long => "%A, %B %d %Y"}
    @locale.decimal_formats     = {:default => "%s", :currency => "$%01.2f", :percent => "%s%%"}
    @locale.wday_names          = [nil, 'Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi']
    @locale.wday_abbrs          = [nil, 'Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam']
    @locale.month_names         = [nil, 'Janvier', 'f&eacute;vrier', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Ao&ucirc;t', 'Septembre', 'Octobre', 'Novembre', 'D&eacute;cembre']
    @locale.month_abbrs         = [nil, 'Jan', 'F&eacute;v', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Ao&ucirc;', 'Sep', 'Oct', 'Nov', 'D&eacute;c']
    @locale.meridian_indicator = {"AM" => "du matin", "PM" => "du soir"}

    Harbor::Locale.register(@locale)
    
    @unlocalized_time = DateTime.parse("1999-12-31 23:00:00") # 1999-12-31 23:00:00
  end
  
  def test_strftime
    localized_time = Harbor::Locale::LocalizedDateTime.new(@unlocalized_time, @locale)
    assert_equal localized_time.strftime("%p"), "du soir"

    assert_equal localized_time.strftime(@locale.time_formats[:default]), "11:00 du soir"
    assert_equal localized_time.strftime(@locale.time_formats[:long]), "12/31/1999 11:00 du soir"
  end
end
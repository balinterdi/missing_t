# Missing T
[![Code Climate](https://codeclimate.com/github/balinterdi/missing_t.png)](https://codeclimate.com/github/balinterdi/missing_t)

Missing T provides a quick way to see which I18n message strings lack their translations in your Ruby project.

## Installation

Missing T comes packaged as a gem, you just have to add it to your Gemfile:

    gem 'missing_t', '~> 0.3.1'

## Running

To find all the messages without translations, you have to be in your project directory and then launch missing_t in the most simple way imaginable:

    $ bundle exec missing_t

All messages that don't have translations will be outputted in a format directly pastable to your locale files:

    fr:
      users:
        name:
        city_of_residence:
        travels:
    es:
      users:
        age:
        city_of_residence:
      events:
        venue: 
        
    
__NOTE__ If no language code is provided, the script will determine which languages need to have translations by gathering all language codes in the localization files and assuming that if there is at least one translation defined for a language then all translations should be defined for it.

If you wish to see all missing translations for a certain language, just provide its language code as a parameter:

    $ bundle exec missing_t fr
    
In this case only missing translations in the provided language will be printed:

    fr:
      users:
        name:
        city_of_residence:
        travels:

## Epilogue

Released under the MIT license.

2009-2013 Balint Erdi

# Missing T
[![Code Climate](https://codeclimate.com/github/balinterdi/missing_t.png)](https://codeclimate.com/github/balinterdi/missing_t)

Missing T provides an easy way to see which internationalized messages lack their translations in a ruby project that uses I18n (e.g Rails apps). Instead of going through the translation files manually, you just call Missing T which gives you a list of all missing translation strings. By default it searches for all languages that you have translation files for. If you given it an option it will only search for translations in that language.

## Installation

Missing T comes packaged as a gem, so you install it via the normal procedure:

    $ gem install missing_t

Also, if you prefer to use it as a plugin to Rails project, you can simply do the following:

    $ ./script/plugin install git://github.com/balinterdi/missing_t.git

## Running

To find all the messages without translations, you have to be in your project directory and then launch missing_t in the most simple way imaginable:

    $ missing_t

You should see all messages that don't have translations on the screen, broken down per file, e.g:

    app/views/users/new.html.erb:
        fr.users.name
        fr.users.city_of_residence
        es.users.age

    app/helpers/user_helper.rb:
        fr.users.travels

__NOTE__ If no language code is provided, the script will determine which languages need to have translations by gathering all language codes in the localization files and assuming that if there is at least one translation defined for a language then all translations should be defined for it.

If you wish to see all the lacking translations for a certain language, just provide its language code as a parameter:

    $ missing_t fr

## Epilogue

That's all about it, let me know if you find any bugs or have suggestions as to what else should the script do. If you wish you can directly contact me at balint.erdi@gmail.com.

[http://github.com/balinterdi/missing_t/](http://github.com/balinterdi/missing_t/)

Copyright (c) 2009-2013 Balint Erdi, released under the MIT license

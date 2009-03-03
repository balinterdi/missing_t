# Missing T

Missing T provides an easy way to see which internationalized messages lack their translations in a ruby project that uses I18n (e.g Rails apps)

## Installation

Missing T comes packaged as a gem, and is hosted on github. If you have not already done so, first add gems.github.com as a rubygems source:

    $ gem sources -a http://gems.github.com
    
And then install the gem itself:

    $ gem install balinterdi-missing_t
    
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
        
If you wish to see all the lacking translations for a certain language, just provide its language code as a parameter:

    $ missing_t fr
    
## Epilogue

That's all about it, let me know if you find any bugs or have suggestions as to what else should the script do. If you wish you can directly contact me at balint.erdi@gmail.com.

[http://github.com/balinterdi/missing_t/](http://github.com/balinterdi/missing_t/)

Copyright (c) 2009 Balint Erdi, released under the MIT license
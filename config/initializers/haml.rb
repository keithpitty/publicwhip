# Only changing this so that it's more compatible with the html generated by the php app
# TODO As soon as that's gone, we can get rid of this
Haml::Template.options[:attr_wrapper] = '"'
# We're only using xhtml rather than the default html5 so that we can easily compare things with tidy
# TODO when we're not doing that get rid of this
Haml::Template.options[:format] = :xhtml

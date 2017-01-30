Pod::Spec.new do |s|
  s.name         = "WillowTreeOuroboros"
  s.version      = "0.2.0"
  s.summary      = "Infinitely scrolling carousel for tvOS"
  s.description  = <<-DESC
                   Ouroboros implements an infinitely scrolling carousel for
                   tvOS, driven by the focus engine.

                   It supports 1 or more centered items grouped into pages.

                   To use from a storyboard, set your collection view's class
                   to InfiniteCarousel and update the itemsPerPage variable.
                   DESC

  s.homepage     = "https://github.com/willowtreeapps/ouroboros"
  s.license      = "MIT"
  s.authors      = { "Ian Terrell" => "ian.terrell@gmail.com" }
  s.source       = { :git => "https://github.com/willowtreeapps/ouroboros.git",
                     :tag => "0.1.0" }

  s.platform = :tvos

  s.source_files = "Ouroboros/**/*.swift",
                   "Ouroboros/**/*.h",
                   "Ouroboros/**/*.m"
  s.public_header_files = "Ouroboros/**/*.h"
end

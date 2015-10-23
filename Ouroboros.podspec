Pod::Spec.new do |s|
  s.name         = "Ouroboros"
  s.version      = "0.0.1"
  s.summary      = "Infinitely scrolling carousels"
  s.description  = <<-DESC
                   Ouroboros implements infinitely scrolling carousels!
                   DESC

  s.homepage     = "https://github.com/willowtreeapps/ouroboros"
  s.license      = "All rights reserved."
  s.authors      = { "Ian Terrell" => "ian.terrell@gmail.com" }

  s.source       = { :git => "https://github.com/willowtreeapps/ouroboros",
                     :tag => "0.0.1" }

  s.platform = :tvos

  s.source_files = "Ouroboros/**/*.swift",
                   "Ouroboros/**/*.h",
                   "Ouroboros/**/*.m"
  s.public_header_files = "Ouroboros/**/*.h"
end

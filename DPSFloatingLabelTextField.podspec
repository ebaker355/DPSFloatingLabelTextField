Pod::Spec.new do |s|
  s.name         = "DPSFloatingLabelTextField"
  s.version      = "2.0.0"
  s.summary      = "A UITextField subclass that creates a floating label from the placeholder text."
  s.description  = <<-DESC
  DPSFloatingLabelTextField is a highly-customizable UITextField subclass that
  creatings a "floating label" from the placeholder string. It also supports
  a bottom line border style.
                   DESC
  s.homepage     = "https://github.com/ebaker355/DPSFloatingLabelTextField"
  s.license      = "MIT"
  s.author             = { "Eric Baker" => "ebaker355@gmail.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/ebaker355/DPSFloatingLabelTextField.git", :tag => "#{s.version}" }
  s.source_files  = "FloatingLabelTextField/Source/*.{h,swift}"
  s.requires_arc = true
end

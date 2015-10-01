#
#  C3-PRO
#
#  Research framework linking FHIR, ResarchKit and i2b2
#

Pod::Spec.new do |s|
  s.name             = "C3PRO"
  s.version          = "1.0.0"
  s.summary          = "Combining 🔥 SMART on FHIR and ResearchKit for data storage into i2b2."
  s.description      = <<-DESC
    Combining 🔥 FHIR and ResearchKit for data storage into i2b2, this
    framework allows you to use FHIR Contract and Questionnaire resources
    directly with ResearchKit and will return FHIR QuestionnaireAnswers to your
    server. There are additional utilities for encryption, geolocation, de-
    identification and data queueing that go well with a research app.
  DESC

  s.homepage         = "https://c3-pro.chip.org"
  s.license          = 'Apache 2'
  s.author           = { "Pascal Pfiffner" => "phase.of.matter@gmail.com" }
  s.source           = { :git => "https://github.com/chb/c3-pro-ios-framework.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Classes/*.swift', 'Consent/*.swift', 'DataQueue/*.swift', 'Encryption/*.swift', 'Identity/*.swift', 'Questionnaire/*.swift'
  s.resource_bundles = {
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'HealthKit'
  s.dependency 'ResearchKit', '~> 1.2', 'SMART', '-> 2.0', 'CryptoSwift', '-> 0.0.16'
end

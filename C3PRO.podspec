#
#  C3-PRO
#
#  Research framework linking FHIR, ResarchKit and i2b2
#

Pod::Spec.new do |s|
  s.name         = "C3PRO"
  s.version      = "1.2"
  s.summary      = "Combining 🔥 SMART on FHIR and ResearchKit for data storage into i2b2."
  s.description  = <<-DESC
    Combining 🔥 FHIR and ResearchKit for data storage into i2b2, the C3-PRO iOS
    framework allows you to use FHIR Contract and Questionnaire resources
    directly with ResearchKit and will return FHIR QuestionnaireResponse to your
    server. There are additional utilities for encryption, geolocation, system
    service access, de-identification, data queueing and HealthKit that go well
    with a research app.
  DESC

  s.homepage     = "https://c3-pro.chip.org"
  s.license      = 'Apache 2'
  s.authors      = { "Pascal Pfiffner" => "phase.of.matter@gmail.com" }
  s.source       = { :git => "https://github.com/p2/c3-pro-ios-framework.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Sources/*/*.swift'
  s.resource_bundles = {
    'C3PRO' => ['*.lproj/C3PRO.strings']
  }
  s.frameworks = 'UIKit', 'HealthKit'
  s.dependency 'SMART', '~> 2.9'
  s.dependency 'ResearchKit', '~> 1.3'
  s.dependency 'CryptoSwift', '~> 0.6'
  s.dependency 'SQLite.swift'
end

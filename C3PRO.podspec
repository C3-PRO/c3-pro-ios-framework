#
#  C3-PRO
#
#  Research framework linking FHIR, ResarchKit and i2b2
#

Pod::Spec.new do |s|
  s.name         = "C3PRO"
  s.version      = "2.0.0"
  s.summary      = "Combining 🔥 SMART on FHIR and ResearchKit for data storage into i2b2."
  s.description  = <<-DESC
    Combining 🔥 FHIR and ResearchKit for data storage into i2b2, the C3-PRO iOS
    framework allows you to use FHIR Contract and Questionnaire resources
    directly with ResearchKit and will return FHIR QuestionnaireResponse to your
    server. There are additional utilities for encryption, geolocation, system
    service access, de-identification, data queueing and HealthKit that go well
    with a research app.
  DESC

  s.homepage     = "https://c3-pro.org"
  s.license      = 'Apache 2'
  s.authors      = { "Pascal Pfiffner" => "phase.of.matter@gmail.com" }
  s.source       = { :git => "https://github.com/c3-pro/c3-pro-ios-framework.git", :tag => s.version.to_s }

  s.platform     = :ios, '9.0'
  s.requires_arc = true

  s.source_files = 'Sources/*/*.swift'
  s.resource_bundles = {
    'C3PRO' => ['*.lproj/C3PRO.strings']
  }
  s.frameworks = 'UIKit', 'HealthKit'
  s.dependency 'SMART', '~> 3.0.0'
  s.dependency 'ResearchKit', '~> 1.4.1'
  s.dependency 'CryptoSwift', '~> 0.6.8'
  s.dependency 'SQLite.swift', '~> 0.11.2'
  s.dependency 'JSONWebToken', '~> 2.0.2'
end

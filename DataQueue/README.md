DataQueue
=========

A FHIR server class primarily used to move FHIR resources, created on device, to a FHIR server, asynchronously.
The idea is that data collection tasks do not need to inform the user whether a file was uploaded or not.
The queue should just try to send them in the background, enqueueing the resources until it's able to successfuly deliver them.

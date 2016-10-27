Migrating Questionnaires
========================

1.0.2 -> 1.4.0+
---------------

At this time, the `Questionnaire` resource is still on a very low maturity level – zero to be specific.
While in 1.0.2, questions were children of groups, these have been merged into `item` with a type in 1.4.

- `QuestionnaireGroup` -> `QuestionnaireItem`
- `QuestionnaireGroupQuestion` -> `QuestionnaireItem`
- `QuestionnaireGroupQuestion.extension (enable-when)` -> `QuestionnaireItem.enableWhen`
- `QuestionnaireGroupPromise` -> `QuestionnaireItemPromise`
- `C3Error.QuestionnaireInvalidNoTopLevel` -> `C3Error.QuestionnaireInvalidNoTopLevelItem`

Same change applies to `QuestionnaireResponse` (maturity level 2 at this time), hence the responses/response-groups now appear as an array on the top level `item` property.
In addition:

- `Questionnaire.encounter` -> `Questionnaire.context`

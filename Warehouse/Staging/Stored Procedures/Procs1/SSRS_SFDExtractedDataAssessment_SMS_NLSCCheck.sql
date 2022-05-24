Create Procedure Staging.SSRS_SFDExtractedDataAssessment_SMS_NLSCCheck @TableName varchar(34)
As
Select * from Relational.PostSFD_SMSEvaluation_NLSCCheck
Where TableName = @TableName
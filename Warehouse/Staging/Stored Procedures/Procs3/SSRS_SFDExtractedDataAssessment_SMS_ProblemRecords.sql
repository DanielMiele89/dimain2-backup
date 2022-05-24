Create Procedure Staging.SSRS_SFDExtractedDataAssessment_SMS_ProblemRecords @TableName varchar(34)
As
Select * from [Relational].[PostSFD_SMSEvaluation_ProblemRecords]
Where TableName = @TableName
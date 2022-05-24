CREATE Procedure Staging.SSRS_SFDExtractedDataAssessment_SMS_CJStageCounts @TableName varchar(34)
As
select * 
from Relational.PostSFD_SMSEvaluation_CJStageCounts as a 
Where TableName = @TableName
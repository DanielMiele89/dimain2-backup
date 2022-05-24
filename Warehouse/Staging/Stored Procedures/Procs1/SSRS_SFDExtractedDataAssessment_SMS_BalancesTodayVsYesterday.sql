CREATE Procedure Staging.SSRS_SFDExtractedDataAssessment_SMS_BalancesTodayVsYesterday @TableName varchar(34)
As
select * 
from Relational.PostSFD_SMS_BalancesTodayVsYesterday as a 
Where TableName = @TableName
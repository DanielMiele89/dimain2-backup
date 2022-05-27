Create Procedure Staging.SSRS_SFDExtractedDataAssessment_SMS_BalancesTodayVsYesterdaySample @TableName varchar(34)
As
Select * from Warehouse.Relational.PostSFD_SMS_BalancesTodayVsYesterday_Sample--Movers
Where TableName = @TableName
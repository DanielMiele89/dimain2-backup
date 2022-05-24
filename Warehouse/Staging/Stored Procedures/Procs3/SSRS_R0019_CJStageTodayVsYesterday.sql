/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0019.

					This pulls out Stats regarding cj stage counts as part of 
					the weekly SFD assessment

Update:			N/A
					
*/
Create Procedure Staging.SSRS_R0019_CJStageTodayVsYesterday
				 @TableName varchar(300)
as

select * from [Staging].[PostSFDEmailEvaluation_CJStageTodayVsYesterday]
Where @TableName = TableName
/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0019.

					Shows a sample of moving CJ Stages between today and yesterday

Update:			N/A
					
*/
CREATE Procedure Staging.SSRS_R0019_CJStageTodayVsYesterday_SampleMovers
				 @TableName varchar(300)
as

select *,ROW_NUMBER() OVER(PARTITION BY Shortcode_Yesterday,Shortcode_Today ORDER BY Newid() DESC) AS RowNO
from [Staging].[PostSFDEmailEvaluation_CJStageTodayVsYesterday_SampleMovers]
Where @TableName = TableName
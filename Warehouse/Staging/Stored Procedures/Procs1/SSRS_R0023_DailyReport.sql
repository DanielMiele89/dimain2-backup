/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0022.

					This pull the contents of the DailyCashBackPlusReport_Data 
					table

Update:			N/A
					
*/
Create Procedure Staging.SSRS_R0023_DailyReport
				 @DataDate Date
as
select * from [Staging].[DailyCashBackPlusReport_Data]
Where DataDate = @DataDate
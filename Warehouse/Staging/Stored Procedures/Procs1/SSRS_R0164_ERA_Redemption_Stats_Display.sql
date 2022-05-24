/*

	Author:			Stuart Barnley

	Date:			2nd June 2017

	Purpose:		Retrieve the E-Redemption data to be used as part of the interal reporting

*/


CREATE Procedure [Staging].[SSRS_R0164_ERA_Redemption_Stats_Display] (@ReportDate Date)
With Execute as Owner
AS

Select [RedeemID]
      ,[Red_Description]
      ,[PartnerID]
      ,[PartnerName]
      ,[WarningStockThreshold]
      ,[StartDate]
      ,[EndDate]
      ,[Redemptions]
      ,[RowNumber]
      ,[Average]
      ,[Stock]
	  ,YTD
From [Staging].[R_0155_ERA_Redemptions_Report] as a
Where Cast(ReportDate as Date) = @ReportDate
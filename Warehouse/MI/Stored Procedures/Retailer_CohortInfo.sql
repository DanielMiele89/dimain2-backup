
-- =============================================
-- Author:		JEA
-- Create date: 24/11/2014
-- Description:	Retailer Reports - information for the last month by cohort
-- =============================================
CREATE PROCEDURE [MI].[Retailer_CohortInfo] 
	(
		@PartnerID INT
		, @ClientServiceRef NVARCHAR(30)
		, @MonthID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

		SELECT c.CustomerAttributeID
		  ,c.ReportDescription AS CohortMonth
		  ,RM.Spenders
		  ,RM.Transactions
		  ,RM.Sales
		  ,RM.ATV
		  ,RM.ATF
	  FROM MI.RetailerReportMetric RM
	  INNER JOIN Relational.SchemeUpliftTrans_Month SUTM on RM.DateID = SUTM.ID
	  INNER JOIN MI.RetailerMetricCustomerAttribute c ON RM.CustomerAttributeID = c.CustomerAttributeID
	  WHERE PartnerID = @PartnerID 
	  AND ClientServiceRef = @ClientServiceRef 
	  AND PaymentTypeID = 0 
	  AND ChannelID = 0 
	  AND Mid_SplitID = 0 
	  AND CumulativeTypeID = 0  -- change for cumulative
	  AND PeriodTypeID = 1
	  AND DateID = @MonthID
	  AND c.[Description] LIKE '%cohort%'

END
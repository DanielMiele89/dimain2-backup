-- =============================================
-- Author:		JEA
-- Create date: 28/11/2014
-- Description:	Returns parameters for the monthly 
--retailer report data driven subscription
-- =============================================
CREATE PROCEDURE [MI].[RetailerReportParams_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @MonthID INT

	SELECT @MonthID = MAX(DateID) FROM MI.RetailerReportMetric WHERE PeriodTypeID = 1

    SELECT CAST('ed.allison@rewardinsight.com' AS VARCHAR(1000)) AS EmailRecipients
	, 'Retailer Monthly Report - ' + p.PartnerName + ' (ref ' + ClientServicesRef + ')' AS EmailTitle
	, 'Retailer_Monthly_Report_' + p.PartnerName + '_ref_' + ClientServicesRef AS FileTitle
	, @MonthID AS MonthID
	, r.PartnerID
	, ClientServicesRef
	, CAST(2 AS INT) AS CumulativeTypeID
	FROM (SELECT DISTINCT PartnerID, ClientServiceRef AS ClientServicesRef
			FROM MI.RetailerReportMetric
			WHERE DateID = @MonthID
			AND CumulativeTypeID = 0) r
	INNER JOIN Relational.[Partner] p ON r.PartnerID = p.PartnerID
	WHERE p.PartnerID = 3960
	ORDER BY PartnerID, ClientServicesRef

END
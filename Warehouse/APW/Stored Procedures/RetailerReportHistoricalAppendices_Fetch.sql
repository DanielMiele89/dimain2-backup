
-- =============================================
-- Author:		JEA
-- Create date: 23/06/2016
-- Description:	Returns parameters for the 
-- historical appendix generation
-- =============================================
CREATE PROCEDURE [APW].[RetailerReportHistoricalAppendices_Fetch] 

AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT DISTINCT p.PartnerID, p.partnername, r.ClientServiceRef
	FROM MI.RetailerReportMetric r
	INNER JOIN relational.[Partner] p on r.PartnerID = p.PartnerID
	WHERE CustomerAttributeID = 0
	AND dateid = 52
	AND PaymentTypeID = 0
	AND ChannelID = 0
	AND Mid_SplitID = 0
	AND CumulativeTypeID = 0
	AND UpliftSales IS NOT NULL

END


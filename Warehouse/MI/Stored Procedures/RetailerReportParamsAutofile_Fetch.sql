-- =============================================
-- Author:		JEA
-- Create date: 04/04/2016
-- Description:	Returns parameters for the monthly 
--retailer report automatic file generation
-- =============================================
CREATE PROCEDURE [MI].[RetailerReportParamsAutofile_Fetch] 
	(
		@MonthID INT = NULL
	)
AS
BEGIN
	
	SET NOCOUNT ON;

	IF @MonthID IS NULL
	BEGIN
		SELECT @MonthID = MAX(DateID) FROM MI.RetailerReportMetric WHERE PeriodTypeID = 1
	END

	DECLARE @MonthDesc VARCHAR(50)

	SELECT @MonthDesc = MonthDesc 
	FROM Relational.SchemeUpliftTrans_Month
	WHERE ID = @MonthID

    SELECT @MonthID AS MonthID
	, @MonthDesc AS MonthDesc
	, r.PartnerID
	, p.PartnerName
	, ClientServicesRef
	FROM (SELECT DISTINCT PartnerID, ClientServiceRef AS ClientServicesRef
			FROM MI.RetailerReportMetric
			WHERE DateID = @MonthID
			AND CumulativeTypeID = 0
			AND UpliftSales IS NOT NULL) r
	INNER JOIN Relational.[Partner] p ON r.PartnerID = p.PartnerID
	WHERE p.PartnerID = 3960
	ORDER BY PartnerID, ClientServicesRef

END

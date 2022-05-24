-- =============================================
-- Author:		JEA
-- Create date: 22/09/2015
-- Description:	Returns the cumulative month start for a given retailer
-- =============================================
CREATE PROCEDURE MI.Retailer_ReportStartMonth 
	(
		@PartnerID INT
		, @ClientServiceRef NVARCHAR(10)
	)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @MonthID INT

	SELECT @MonthID = MAX(MonthID)
	FROM
	(
		SELECT Reporting_Start_MonthID AS MonthID
		FROM Relational.Master_Retailer_Table
		WHERE PartnerID = @PartnerID

		UNION

		SELECT MIN(DateID) AS MonthID
		FROM MI.RetailerReportMetric
		WHERE PartnerID = @PartnerID
		AND ClientServiceRef = @ClientServiceRef
	) M

	SELECT @MonthID AS MonthID, MonthDesc AS ReportStartMonth
	FROM Relational.SchemeUpliftTrans_Month
	WHERE ID = @MonthID

END
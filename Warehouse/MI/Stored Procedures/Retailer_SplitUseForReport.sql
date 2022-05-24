-- =============================================
-- Author:		JEA
-- Create date: 04/12/2014
-- Description:	Used for the display logic of the retailer monthly reports
-- =============================================
CREATE PROCEDURE MI.Retailer_SplitUseForReport 
	(
		@PartnerID INT
		, @SplitPosition INT
	)
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT SplitPosition AS Split_Use_For_Report, Count(1) AS maxStatus
	FROM MI.RetailerReportMID_Split
	WHERE PartnerID = @PartnerID AND SplitPosition = @SplitPosition
	GROUP BY SplitPosition

END
-- =============================================
-- Author:		JEA
-- Create date: 16/08/2016
-- Description:	Fetches cumulative dates for Weekly Summary Reports
-- =============================================
CREATE PROCEDURE APW.WeeklySummary_CumulativeStartDates_Fetch 

AS
BEGIN

	SET NOCOUNT ON;

	SELECT PartnerID AS RetailerID
		, CAST(Advertised_Launch_Date AS date) AS CumulativeStartDate
	FROM Relational.Master_Retailer_Table

END

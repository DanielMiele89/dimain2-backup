
/**********************************************************************

	Author:		 Hayden Reid
	Create date:	 28/06/2016
	Description:	 Fetches the report structure for 'CaffeNeroMidSales' Report that
				 details all of the sales split by MIDs across all publishers

***********************************************************************/
CREATE PROCEDURE [MI].[CNMIDSales_Fetch]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    DECLARE @MaxDate date = (SELECT MAX(StartDate) FROM MI.CNMIDSales)

    ;with mnths
    AS
    (
	   SELECT MIN(StartDate) as StartDate, MIN(EndDate) as EndDate
	   FROM MI.CNMIDSales

	   UNION ALL

	   SELECT DATEADD(WEEK, 4, StartDate), DATEADD(WEEK, 4, EndDate)
	   FROM mnths
	   WHERE StartDate < @MaxDate
    ),
    merged
    AS
    (
	   SELECT * from mnths
	   CROSS JOIN (SELECT DISTINCT Scheme, MerchantID, FullAddress, PostCode FROM MI.CNMIDSales) x
    )
    SELECT
	    m.Scheme
	    , m.StartDate
	    , m.EndDate
	   -- , COALESCE((STUFF((SELECT DISTINCT '/'+MerchantID FROM MI.CNMIDSales s WHERE s.PostCode = m.PostCode and s.FullAddress like '%' + LEFT(m.FullAddress, 10) + '%' FOR XML PATH('')), 1, 1, '')), m.MerchantID) MerchantID
	    , m.MerchantID
	    , m.FullAddress + ISNULL(NULLIF(', ' + m.PostCode, ', '), '') FullAddress
	    , ISNULL(Total, 0) Total
    FROM merged m
    LEFT JOIN MI.CNMIDSales cn on cn.StartDate = m.StartDate 
	   and cn.EndDate = m.EndDate 
	   and m.MerchantID = cn.MerchantID 
	   and cn.Scheme = m.Scheme
    WHERE m.Scheme = 'MyRewards'
    ORDER BY m.Scheme, m.MerchantID, m.StartDate

END
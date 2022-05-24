
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 20/06/2016
	Description: 

***********************************************************************/
CREATE PROCEDURE Prototype.CNMIDSales_Fetch
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

DECLARE @MaxDate date = (SELECT MAX(StartDate) FROM Prototype.CNMIDSales)

;with mnths
AS
(
    SELECT MIN(StartDate) as StartDate, MIN(EndDate) as EndDate
    FROM Prototype.CNMIDSales

    UNION ALL

    SELECT DATEADD(month, 1, StartDate), EOMONTH(DATEADD(month, 1, EndDate))
    FROM mnths
    WHERE StartDate < @MaxDate
),
merged
AS
(
    SELECT * from mnths
    CROSS JOIN (SELECT DISTINCT Scheme, MerchantID FROM Prototype.CNMIDSales) x
)
SELECT
	m.Scheme
	, m.StartDate
	, m.EndDate
	, m.MerchantID
	, FullAddress
	, Total
FROM merged m
LEFT JOIN Prototype.CNMIDSales cn on cn.StartDate = m.StartDate 
    and cn.EndDate = m.EndDate 
    and m.MerchantID = cn.MerchantID 
    and cn.Scheme = m.Scheme
ORDER BY m.Scheme, m.MerchantID, m.StartDate



END

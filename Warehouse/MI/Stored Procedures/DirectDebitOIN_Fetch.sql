-- =============================================
-- Author:		JEA
-- Create date: 04/10/2018
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[DirectDebitOIN_Fetch] 
	
AS
BEGIN
	
	DECLARE @StartDate DATE, @EndDate DATE

	SET NOCOUNT ON;

    SET @StartDate = DATEADD(YEAR,-1,DATEFROMPARTS(YEAR(GETDATE()),1,1))
	SET @EndDate = DATEADD(DAY, -1, DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1))

	SELECT d.OIN
		, d.Category2 AS Category
		, d.SupplierName AS Supplier
		, DATEFROMPARTS(YEAR(a.TranDate), MONTH(a.TranDate),1) AS DDMonth
		, SUM(a.Amount) AS DDSpend
	FROM Relational.AdditionalCashbackAward a WITH (NOLOCK)
	INNER JOIN Relational.DirectDebitOriginator d ON a.DirectDebitOriginatorID = d.ID
	WHERE TranDate BETWEEN @StartDate AND @EndDate
	GROUP BY d.OIN
		, d.Category2
		, d.SupplierName
		, DATEFROMPARTS(YEAR(a.TranDate), MONTH(a.TranDate),1)

END

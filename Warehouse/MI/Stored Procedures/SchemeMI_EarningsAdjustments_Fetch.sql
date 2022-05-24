
-- =============================================
-- Author:		JEA
-- Create date: 12/12/2014
-- Description:	Retrieves earnings adjustments as a result of opt out and deactivation
-- =============================================
CREATE PROCEDURE [MI].[SchemeMI_EarningsAdjustments_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT AdditionalCashbackAdjustmentID AS AdjustmentID
		, FanID
		, AddedDate
		, CashbackEarned AS CashbackAdjustment
	FROM Relational.AdditionalCashbackAdjustment
	WHERE AdditionalCashbackAdjustmentTypeID IN (1,3)

END


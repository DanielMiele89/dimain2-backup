-- =============================================
-- Author:		JEA
-- Create date: 20/07/2015
-- Description:	Retrieves customer balances
-- =============================================
CREATE PROCEDURE [MI].[RBSMIPortal_CustomerBalances_Fetch]
AS
BEGIN

	SET NOCOUNT ON;

	SELECT c.FanID
		, c.CashbackTotal
		, c.CashbackCleared
		, c.LoyaltyDate
		, c.DateTypePeriodID
		, b.ID AS CashbackBandingID
	FROM
	(
    SELECT c.FanID
		, c.ClubcashPending AS CashbackTotal
		, c.ClubCashAvailable AS CashbackCleared
		, d.LoyaltyDate
		, d.DateTypePeriodID
	FROM Staging.Customer_CashbackBalances c
	INNER JOIN MI.LoyaltyBalanceDates d ON c.[Date] = d.LoyaltyDate
	) c
	INNER JOIN MI.RBSMIPortal_CashbackBandingClass b ON c.CashbackTotal BETWEEN B.MinAmt AND B.MaxAmt

END
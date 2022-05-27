

-- =============================================
-- Author:		JEA
-- Create date: 12/06/2015
-- Description:	Fetches a list of earnings for incremental load
-- =============================================
CREATE PROCEDURE [MI].[RBSMIPortal_SchemeEarnings_PartnerTrans_Fetch] 

AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT s.SchemeTransID 
		, pt.FanID
		, pt.TransactionAmount AS Spend
		, pt.CashbackEarned AS Earnings
		, pt.AddedDate
		, p.BrandID
		, ISNULL(pt.AboveBase,0) AS AboveBase
		, pt.AddedDate As AddeDateTime
		, pt.IronOfferID
		, CAST(0 AS TINYINT) AS AdditionalCashbackAwardTypeID
		, pt.PaymentMethodID
		, pt.TransactionDate AS TranDate
		, pt.ActivationDays
	FROM Warehouse.Relational.PartnerTrans pt
		INNER JOIN Relational.[Partner] p on pt.PartnerID = p.PartnerID
		INNER JOIN MI.SchemeTransUniqueID s ON pt.MatchID = s.MatchID
	WHERE pt.EligibleForCashback = 1

END



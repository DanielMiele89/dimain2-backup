-- =============================================
-- Author:		JEA
-- Create date: 07/06/2013
--MODIFIED 08/07/2014
-- Description:	Fetches a list of scheme transactions for incremental load
-- CJM 20161117  recommended index [IX_MI_SchemeTransUniqueID_MatchID] ON [MI].[SchemeTransUniqueID] was rebuilt with SchemeTransID in the INCLUDE list.
-- CJM 20190612 added an index: CREATE INDEX ix_Stuff03 ON [Relational].[PartnerTrans] (MatchID, PartnerID)
-- =============================================
CREATE PROCEDURE [MI].[SchemeTransList_WithNoPostImport_Fetch] 
	(
		@Incremental BIT = 1
	)
AS
BEGIN
	
	SET NOCOUNT ON;

	--IF DATENAME(WEEKDAY,GETDATE()) = 'Sunday'
	--BEGIN
	--	SET @Incremental = 0
	--END

	DECLARE @PTAddedDateLoaded DATE, @ACAAddedDateLoaded DATE
	SELECT @PTAddedDateLoaded = MAX(AddedDate) FROM RBSMIPortal.PartnerTransAddedDateLoaded
	SELECT @ACAAddedDateLoaded = MAX(AddedDate) FROM RBSMIPortal.AdditCashAwardAddedDateLoaded

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
		, c.TranWeekID
		, c.TranMonthID
		, cu.GenderID
		, cu.AgeBandID
		, cu.BankID
		, cu.RainbowID
		, cu.ChannelPreferenceID
		, cu.ActivationMethodID
	FROM Relational.PartnerTrans pt
		INNER JOIN Relational.[Partner] p on pt.PartnerID = p.PartnerID
		INNER JOIN MI.SchemeTransUniqueID s ON pt.MatchID = s.MatchID
		INNER JOIN RBSMIPortal.CalendarWeekMonth_ST c ON pt.AddedDate = c.CalendarDate
		INNER JOIN RBSMIPortal.Customer_ST cu ON pt.FanID = cu.FanID
	WHERE pt.EligibleForCashback = 1
	AND (@Incremental = 0 OR pt.AddedDate > @PTAddedDateLoaded)

	UNION ALL

	SELECT s.SchemeTransID
		, a.FanID
		, a.Amount AS Spend
		, a.CashbackEarned AS Earnings
		, a.AddedDate
		, CAST(COALESCE(p.BrandID,0) AS INT) AS BrandID
		, CAST(0 AS BIT) AS AboveBase
		, a.AddedDate AS AddedDateTime
		, CAST(NULL AS INT) AS IronOfferID
		, CAST(a.AdditionalCashbackAwardTypeID AS TINYINT) AS AdditionalCashbackAwardTypeID
		, a.PaymentMethodID AS PaymentMethodID
		, c.TranWeekID
		, c.TranMonthID
		, cu.GenderID
		, cu.AgeBandID
		, cu.BankID
		, cu.RainbowID
		, cu.ChannelPreferenceID
		, cu.ActivationMethodID
	FROM Relational.AdditionalCashbackAward a
		INNER JOIN MI.SchemeTransUniqueID s ON a.FileID = s.FileID and a.RowNum = s.RowNum
		LEFT OUTER JOIN Relational.PartnerTrans pt ON a.MatchID = pt.MatchID
		LEFT OUTER JOIN Relational.[Partner] p ON pt.PartnerID = p.PartnerID
		INNER JOIN RBSMIPortal.CalendarWeekMonth_ST c ON a.AddedDate = c.CalendarDate
		INNER JOIN RBSMIPortal.Customer_ST cu ON a.FanID = cu.FanID
	WHERE (@Incremental = 0 OR a.AddedDate > @ACAAddedDateLoaded)

END
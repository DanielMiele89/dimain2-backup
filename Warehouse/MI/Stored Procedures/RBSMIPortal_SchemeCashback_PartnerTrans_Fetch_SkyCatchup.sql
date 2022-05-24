

-- =============================================
-- Author:		JEA
-- Create date: 15/06/2015
-- Description:	staging info for scheme cashback
-- =============================================
CREATE PROCEDURE [MI].[RBSMIPortal_SchemeCashback_PartnerTrans_Fetch_SkyCatchup]
	(
		@Incremental BIT = 1
	)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @PTAddedDate DATE

	SELECT @PTAddedDate = MAX(AddedDate) FROM RBSMIPortal.SchemeCashback_PT_AddedDateLoaded

    SELECT s.SchemeTransID
		, pt.FanID
		, pt.TransactionAmount AS Spend
		, pt.CashbackEarned AS Cashback
		, pt.AddedDate
		, pt.TransactionDate AS TranDate
		, p.PartnerID
		, p.PartnerName
		, CAST(0 AS TINYINT) AS AdditionalCashbackAwardTypeID
		, CAST(0 AS TINYINT) AS AdditionalCashbackAdjustmentTypeID
		, CAST(0 AS TINYINT) AS AdditionalCashbackAdjustmentCategoryID
		, CAST('' AS VARCHAR(50)) AS DDCategory
		, CAST(pt.AboveBase AS BIT) AS OfferAboveBase
		, pt.PaymentMethodID
		, pm.[Description] AS PaymentMethod
		, CAST(COALESCE(e.ClientServicesRef, h.OfferName, cast(i.IronOfferName as varchar(200)), '') AS VARCHAR(200)) AS OfferName
		, pt.ActivationDays
		, p.PartnerID AS PartnerMatchID
	FROM Relational.PartnerTrans pt	WITH (NOLOCK)
	INNER JOIN MI.vwPartnerAlternate p ON pt.PartnerID = p.PartnerMatchID
	INNER JOIN MI.SchemeTransUniqueID s WITH (NOLOCK) ON pt.MatchID = s.MatchID
	INNER JOIN Relational.PaymentMethod pm ON pt.PaymentMethodID = pm.PaymentMethodID
	LEFT OUTER JOIN Relational.IronOffer i ON pt.IronOfferID = i.IronOfferID
	LEFT OUTER JOIN Staging.IronOffer_Campaign_EPOCU e ON pt.IronOfferID = e.OfferID
	LEFT OUTER JOIN 
		(
			SELECT o.IronOfferID, o.ClientServicesRef AS OfferName, c.CampaignName AS OfferDesc
			FROM Relational.IronOffer_Campaign_HTM o
			LEFT OUTER JOIN Relational.CBP_CampaignNames c ON O.ClientServicesRef = c.ClientServicesRef
		) h ON pt.IronOfferID = h.IronOfferID
	WHERE --@Incremental = 0 OR pt.AddedDate > @PTAddedDate
	pt.PartnerID = 4729
	and pt.TransactionDate <= '2019-05-17'

END
-- =============================================
-- Author:		JEA
-- Create date: 13/10/2016
-- Description:	Loads IronOfferSpendStretch
-- on allPublisherWarehouse
-- =============================================
CREATE PROCEDURE APW.IronOfferSpendStretch_Fetch 
	WITH EXECUTE AS 'ProcessOp'
AS
BEGIN

	SET NOCOUNT ON;

	SELECT IronOfferID,
		CAST(RequiredMinimumBasketSize AS money) AS SpendStretchAmount
	FROM (
			SELECT i.ID AS IronOfferID,
				i.Name as IronOfferName,
				pcr.CommissionRate as CashbackRate_Pct,
				pcr.RequiredMinimumBasketSize,
				ROW_NUMBER() OVER(PARTITION BY I.ID ORDER BY pcr.CommissionRate DESC) AS RowNo
			FROM SLC_Report.dbo.IronOffer as i
			INNER JOIN SLC_Report.dbo.PartnerCommissionRule as pcr
				   ON i.ID = pcr.RequiredIronOfferID
			WHERE [status] = 1 AND TypeID = 1
	) AS a
	WHERE RowNo = 1
	AND RequiredMinimumBasketSize IS NOT NULL
	AND RequiredMinimumBasketSize > 0

END
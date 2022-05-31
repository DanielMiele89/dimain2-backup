CREATE Procedure [Segmentation].[ROC_ShopperSegment_ClosedOffers] (@Date Date)
As

Begin
	

	--DECLARE @Date DATE = '2019-09-26'
	DECLARE @RowNo INT = 0

	UPDATE sto
	SET LiveOffer = 0
	FROM [Segmentation].[ROC_Shopper_Segment_To_Offers] sto
	INNER JOIN [Relational].[IronOffer] iof
		ON sto.IronOfferID = iof.ID
	WHERE iof.EndDate < @Date
	AND LiveOffer = 1

	SET @RowNo = @@RowCount

	SELECT 'LiveOffers Unticked' AS [Description]
		 , @RowNo as RowsUpdated

End
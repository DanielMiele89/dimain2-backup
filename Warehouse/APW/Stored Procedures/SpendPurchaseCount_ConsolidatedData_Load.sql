-- =============================================
-- Author:		JEA
-- Create date: 20/06/2016
-- Description:	Populates consolidated spend and purchase count information
-- =============================================
CREATE PROCEDURE [APW].[SpendPurchaseCount_ConsolidatedData_Load] 
(
	@RetailerID INT, @IsControl BIT
)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @Spend MONEY

	SELECT @Spend = SUM(Spend)
	FROM APW.SpendPurchaseCount_CINSpend

	IF @Spend > 0
	BEGIN

		INSERT INTO APW.SpendPurchaseCount_RetailerSPS(RetailerID, IsControl, SPS)
		SELECT @RetailerID, @IsControl, SUM(Spend)/COUNT(1)
		FROM APW.SpendPurchaseCount_CINSpend

		INSERT INTO APW.SpendPurchaseCount_RetailerAvgPurchases(RetailerID
			, IsControl
			, TranCount
			, CustomerCount
			, AvgPurchases)

		SELECT @RetailerID
			, @IsControl
			, SUM(TranCount) AS TranCount
			, COUNT(1) AS CustomerCount
			, CAST(SUM(TranCount) AS float)/CAST(COUNT(1) AS float) AS AvgPurchases
		FROM APW.SpendPurchaseCount_CINSpend

		UPDATE APW.SpendPurchaseCount_CINSpend
		SET TranCount = 10
		WHERE TranCount > 10

		INSERT INTO APW.SpendPurchaseCount_RetailerPurchaseCount(RetailerID, IsControl, PurchaseCount, CustomerCount)
		SELECT @RetailerID, @IsControl, TranCount, COUNT(*)
		FROM APW.SpendPurchaseCount_CINSpend
		GROUP BY TranCount

	END

END

-- =============================================
-- Author:		<Shaun H.>
-- Create date: <21/06/2017>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE ExcelQuery.ROCEFT_RBS_PmtMethodSplit_Calculate
AS
BEGIN
	SET NOCOUNT ON;

	Declare @EndDate Date = EOMONTH(DATEADD(MONTH,-1,EOMONTH(GETDATE() + 7)))
	Declare @StartDate Date = DATEADD(DAY,1,DATEADD(MONTH,-4,@EndDate))

	IF OBJECT_ID('tempdb..#PmtMethodProportions') IS NOT NULL DROP TABLE #PmtMethodProportions
	SELECT		DISTINCT PartnerID
				,CASE
					WHEN PaymentMethodID = 0 THEN 'Debit Card'
					WHEN PaymentMethodID = 1 THEN 'Credit Card'
					ELSE 'Error'
				 END AS PaymentMethod,
				sum(TransactionAmount) over (Partition by PartnerID, PaymentMethodID)/sum(TransactionAmount) over (partition by partnerId) as PmtProportion
	INTO		#PmtMethodProportions
	FROM		Warehouse.Relational.PartnerTrans 
	WHERE		Transactiondate between @StartDate AND @EndDate

	IF OBJECT_ID('Warehouse.ExcelQuery.ROCEFT_RBS_PaymentMethodSplit') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.ROCEFT_RBS_PaymentMethodSplit
	SELECT		a.PartnerID,
				BrandID,
				(1-PmtProportion)/PmtProportion + 1 as CCMultiplier
	INTO		Warehouse.ExcelQuery.ROCEFT_RBS_PaymentMethodSplit
	FROM		#PmtMethodProportions a
	INNER JOIN  Warehouse.relational.partner b on a.PartnerID = b.PartnerID		
	WHERE		PaymentMethod = 'Debit Card'
END
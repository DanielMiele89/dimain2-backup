-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [RBSMIPortal].[SchemeTransCashback_SetLoadedDates]

AS
BEGIN

	SET NOCOUNT ON;

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @CashPTAddedDate DATE, @CashACAAddedDate DATE, @CashACAJAddedDate DATE

	SELECT @CashPTAddedDate = MAX(AddedDate)
	FROM Relational.PartnerTrans

	SELECT @CashACAAddedDate = MAX(AddedDate)
	FROM Relational.AdditionalCashbackAward

	SELECT @CashACAJAddedDate = MAX(AddedDate)
	FROM Relational.AdditionalCashbackAdjustment ac 
		INNER JOIN Relational.AdditionalCashbackAdjustmentType at ON ac.AdditionalCashbackAdjustmentTypeID = at.AdditionalCashbackAdjustmentTypeID
		INNER JOIN Relational.AdditionalCashbackAdjustmentCategory c ON at.AdditionalCashbackAdjustmentCategoryID = c.AdditionalCashbackAdjustmentCategoryID
		INNER JOIN Relational.Customer cu ON ac.FanID = cu.FanID
	WHERE c.AdditionalCashbackAdjustmentCategoryID > 1

	UPDATE RBSMIPortal.SchemeCashback_PT_AddedDateLoaded SET AddedDate = @CashPTAddedDate
	UPDATE RBSMIPortal.SchemeCashback_ACA_AddedDateLoaded SET AddedDate = @CashACAAddedDate
	UPDATE RBSMIPortal.SchemeCashback_acaj_AddedDateLoaded SET AddedDate = @CashACAJAddedDate

END
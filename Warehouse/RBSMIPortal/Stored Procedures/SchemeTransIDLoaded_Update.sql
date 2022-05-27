-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [RBSMIPortal].[SchemeTransIDLoaded_Update] 
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @PTAddedDateLoaded DATE, @ACAAddedDateLoaded DATE
	SELECT @PTAddedDateLoaded = MAX(AddedDate) FROM Relational.PartnerTrans
	SELECT @ACAAddedDateLoaded = MAX(AddedDate) FROM Relational.AdditionalCashbackAward

    UPDATE RBSMIPortal.PartnerTransAddedDateLoaded
	SET AddedDate = @PTAddedDateLoaded

	UPDATE RBSMIPortal.AdditCashAwardAddedDateLoaded
	SET AddedDate = @ACAAddedDateLoaded

END

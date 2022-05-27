-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE RBSMIPortal.SchemeCashback_ACAJ_AddedDateLoaded_Update 
	(
		@LoadedDate DATE
	)
AS
BEGIN

	SET NOCOUNT ON;

    UPDATE RBSMIPortal.SchemeCashback_ACAJ_AddedDateLoaded SET AddedDate = @LoadedDate

END

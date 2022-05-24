-- =============================================
-- Author:		JEA
-- Create date: 30/04/2014
-- Description:	Clears down SchemeAgeBand table used by the RBS
-- MI Portal incremental load
-- =============================================
CREATE PROCEDURE [MI].[RBSPortal_SchemeAgeBand_Clear]

AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE MI.RBSPortal_SchemeAgeBand

END

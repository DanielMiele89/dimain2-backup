-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE DIRepETL.FullLoadTables_Clear 

AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE dbo.Fan
	TRUNCATE TABLE dbo.Pan
	TRUNCATE TABLE dbo.PaymentCard

END

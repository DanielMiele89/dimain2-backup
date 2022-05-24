-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [APW].[WeeklyNLETables_Clear] 

AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE APW.WeeklyNLECustomer
	TRUNCATE TABLE APW.WeeklyNLECustomer_Stage
	TRUNCATE TABLE APW.WeeklyNLEDates

END

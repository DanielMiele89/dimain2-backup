-- =============================================
-- Author:		JEA
-- Create date: 03/11/2016
-- Description:	Truncates the staging customer table
-- =============================================
CREATE PROCEDURE APW.DirectLoad_Staging_Customer_Clear 

AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE APW.DirectLoad_Staging_Customer

END

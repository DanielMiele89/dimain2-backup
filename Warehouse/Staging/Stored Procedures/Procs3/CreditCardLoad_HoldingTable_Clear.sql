-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE Staging.CreditCardLoad_HoldingTable_Clear 
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

    TRUNCATE TABLE Staging.CreditCardLoad_InitialStage

END
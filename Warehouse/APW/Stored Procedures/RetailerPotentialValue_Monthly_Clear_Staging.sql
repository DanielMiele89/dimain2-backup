/**************************************************************************
-- Author: Jason Shipp
-- Create date: 26/01/2018
-- Description:	
	Clear staging tables on Warehouse related to the RetailerPotentialValue_Monthly report

-- Modification History:
***************************************************************************/

CREATE PROCEDURE APW.RetailerPotentialValue_Monthly_Clear_Staging

AS 
BEGIN

	SET NOCOUNT ON;

	TRUNCATE TABLE APW.RetailerPotentialValue_Monthly_Cardholder;
	
END
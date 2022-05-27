/******************************************************************************
Author: Jason Shipp
Created: 22/03/2018
Purpose: 
	Clear nFI.Relational.AmexOffer table, before duplicating from AllPublisherWarehouse
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Staging.ControlSetup_Clear_AMEX_Offers
	
AS
BEGIN
	
	SET NOCOUNT ON;

	TRUNCATE TABLE nFI.Relational.AmexOffer;

END
/**************************************************************************
-- Author: Jason Shipp
-- Create date: 25/01/2018
-- Description:	
	Create indexs on APW.RetailerPotentialValue_Monthly_Cardholder table

-- Modification History:
***************************************************************************/

CREATE PROCEDURE APW.RetailerPotentialValue_Monthly_Cardholder_Index

AS 
BEGIN

	SET NOCOUNT ON;

	CREATE CLUSTERED INDEX CIX_RetailerPotentialValue_Monthly_Cardholder
	ON APW.RetailerPotentialValue_Monthly_Cardholder (FanID)

	CREATE NONCLUSTERED INDEX IX_RetailerPotentialValue_Monthly_Cardholder
	ON APW.RetailerPotentialValue_Monthly_Cardholder (ActiveFromDate)

END
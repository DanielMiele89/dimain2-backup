/******************************************************************************
Author: Jason Shipp
Created: 28/11/2018
Purpose: 
	- Fetch exposed IronOfferCyclesIDs for which members need to be loaded into Warehouse.Relational.campaignhistory
		 
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Staging.ControlSetup_RBS_Fetch_Exposed_IOCIDs
	
AS
BEGIN
	
	SET NOCOUNT ON;

	Declare @IOCID int = (Select Max(IronOfferCyclesID) From Warehouse.Relational.campaignhistory)+1
	Declare @IOCID_Max int = (Select Max(IronOfferCyclesID) From Warehouse.Relational.IronOfferCycles)

	Select Distinct 
		c.ironoffercyclesid
	From Warehouse.Relational.IronOfferCycles c
	Where 
		c.ironoffercyclesid between @IOCID and @IOCID_Max
		And not exists (Select null from Warehouse.Relational.campaignhistory h where c.ironoffercyclesid = h.ironoffercyclesid)
	Order by 
		c.ironoffercyclesid ASC;

END
/******************************************************************************
Author: Jason Shipp
Created: 28/11/2018
Purpose: 
	- Refresh Warehouse.Staging.ControlSetup_CampaignHistoryStaging table with exposed members for a new IronOfferCyclesID
		 
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Staging.ControlSetup_RBS_Load_Exposed_Members_Staging (@IOCID int)
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Add exposed members to Warehouse.Relational.campaignhistory for new IronOfferCyclesIDs added to Warehouse.Relational.ironoffercycles
	******************************************************************************/

	Truncate table Warehouse.Staging.ControlSetup_CampaignHistoryStaging;

	If object_id('tempdb..#Customer') is not null drop table #Customer;
	
	Select 
		ioc.ironoffercyclesid
		, ioc.ironofferid
		, c.FanID
		, c.compositeid
		, oc.StartDate
		, oc.EndDate
	Into #Customer
	From Warehouse.relational.ironoffercycles ioc
	Inner join Warehouse.Relational.offercycles oc
		on ioc.OfferCyclesID = oc.OfferCyclesID
	Inner join Warehouse.relational.Customer c
		on (c.DeactivatedDate > oc.StartDate or c.DeactivatedDate is null)
	Where
		ioc.ironoffercyclesid = @IOCID;

	Insert into Warehouse.Staging.ControlSetup_CampaignHistoryStaging (ironoffercyclesid, fanid)

	Select distinct
		c2.ironoffercyclesid
		, c2.FanID
	From #Customer c2
	Inner join slc_report.dbo.IronOfferMember iom
		ON iom.IronOfferID = c2.ironofferid 
		AND iom.CompositeID = c2.compositeid
		AND iom.StartDate <= c2.EndDate
		AND (iom.EndDate >= c2.StartDate or iom.EndDate is null);

END
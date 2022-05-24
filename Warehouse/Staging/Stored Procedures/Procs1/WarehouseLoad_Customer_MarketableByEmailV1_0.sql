--Use Warehouse
/******************************************************************************************

	Author:			Stuart Barnley
	
	Date:			27-02-2015
	
	Purpose:		To be a single location setting MARKETABLEBYEMAIL on the Customer table


******************************************************************************************/
CREATE Procedure Staging.WarehouseLoad_Customer_MarketableByEmailV1_0
As
-------------------------------------------------------------------------------------------
---------------------------Create a list of customers with no cards------------------------
-------------------------------------------------------------------------------------------

if object_id('tempdb..#NoCards') is not null drop table #NoCards
Select Distinct FanID
Into #NoCards
from Relational.CustomerPaymentMethodsAvailable as a
Where	a.PaymentMethodsAvailableID = 3 and
		a.EndDate is null

Create Index idx_NoCards_FanID on #NoCards (FanID)
-------------------------------------------------------------------------------------------
----------------------------Set to 1 if active on the scheme---------------------------
-------------------------------------------------------------------------------------------
Update Relational.Customer
Set MarketableByEmail = 1
Where	(	LaunchGroup is not null	or ActivatedDate >= 'Aug 08, 2013')	and				--not control
		CurrentlyActive = 1 and
		Unsubscribed = 0 and					 
   		Hardbounced = 0 and
		EmailStructureValid = 1 and
   		ActivatedOffline = 0 and 
		Len(Postcode) >= 3 and
		SourceUID not in (Select Distinct SourceUID from Staging.Customer_DuplicateSourceUID) and
		FanID not in (Select FanID from #NoCards)
-------------------------------------------------------------------------------------------
--------------------------------Set to 0 if In Unsubscribed List---------------------------
-------------------------------------------------------------------------------------------
Update Relational.Customer
Set MarketableByEmail = 0
from relational.customer as c
inner join Relational.SmartFocusUnsubscribes as sfu
	on c.fanid = sfu.fanid and c.email = sfu.email 
Where	sfu.enddate is null and
		c.MarketableByEmail = 1
-------------------------------------------------------------------------------------------
-----------------Set to 0 if In Non-Unsubscribed exclusion List----------------------------
-------------------------------------------------------------------------------------------
Update Relational.Customer
Set MarketableByEmail = 0
from relational.customer as c
inner join [Relational].[SmartFocusExclusions_NonUnsubscribes] as sfu
	on	c.fanid = sfu.fanid and 
		c.MarketableByEmail = 1
-------------------------------------------------------------------------------------------
------------------------Old control group and not reactivated------------------------------
-------------------------------------------------------------------------------------------
Update Relational.Customer
Set MarketableByEmail = 0
From Relational.Customer as c
inner join Archive_Light.Prod.NobleFanAttributes as a
	on c.CompositeID = a.CompositeID
Where	a.IsControl = 1 and 
		c.ActivatedDate < 'Aug 08, 2013' and
		c.MarketableByEmail = 1
-------------------------------------------------------------------------------------------
-----------------Set to 0 if In Non-Unsubscribed exclusion List----------------------------
-------------------------------------------------------------------------------------------

Update Relational.Customer
Set MarketableByEmail = 1
Where	LaunchGroup in ('Init','STF1','STF2') and 
		CurrentlyActive = 1 and ----------------Customer is still active on the scheme
		EmailStructureValid = 1 and
		ActivatedOffline = 0 and 
		Len(Postcode) >= 3 and
		SourceUID not in (Select SourceUID  from Staging.Customer_DuplicateSourceUID) and
		FanID not in (Select FanID from #NoCards) and
		MarketableByEmail = 0
		
-------------------------------------------------------------------------------------------
------------------------Set to 1 if staff member of Reward or RBSG-------------------------
-------------------------------------------------------------------------------------------		
		
Update Relational.Customer
Set MarketableByEmail = 1
From Warehouse.Relational.Customer as c
inner join Warehouse.Staging.StaffRecordsNotToBeUnsubscribed as sr
	on c.FanID = sr.FanID
Where	CurrentlyActive = 1 and
		EmailStructureValid = 1 and
		MarketableByEmail = 0 and
		Len(Postcode) >= 3

/***********************************************************************************************/

-------------------------------------------------------------------------------
--------------------------Find those who HardBounced---------------------------
-------------------------------------------------------------------------------
if object_id('tempdb..#HB') is not null drop table #HB
select Distinct c.FanID
into #HB
from Relational.Customer as c
where	c.Unsubscribed = 0 and 
		c.hardbounced = 1 and -- must have already hard bounced
		c.EmailStructureValid = 1 and  
		c.CurrentlyActive = 1 and -- must be active
		c.Marketablebyemail = 0 and -- Currently not emailable
		len(c.PostCode) >=3 and
		c.SourceUID not in (Select SourceUID  from Staging.Customer_DuplicateSourceUID) and
		c.FanID not in (Select FanID from #NoCards)
-------------------------------------------------------------------------------
-------------Find those who HardBounced - Latest Date of Bounce----------------
-------------------------------------------------------------------------------
if object_id('tempdb..#HBDate') is not null drop table #HBDate
select Distinct	
		ee.FanID,
		Max(ee.EventDateTime) as HB_Date
Into #HBDate
from Relational.EmailEvent as ee with (nolock)
inner join #HB as hb
	on ee.FanID = hb.FanID
Where ee.EmailEventCodeID = 702  -- Hard Bounce Event Code
Group by ee.FanID
-------------------------------------------------------------------------------
------------------Find those who changed email after Bounce--------------------
-------------------------------------------------------------------------------
--Find the change of email address entry in the change log
if object_id('tempdb..#NewEmail_Fans') is not null drop table #NewEmail_Fans
Select Distinct iad.FanID
Into #NewEmail_Fans
from Staging.InsightArchiveData as iad
inner join #HBDate as h
	on	iad.FanID = h.FanID and
		typeID = 2
Where	iad.[Date] > h.HB_Date and -- changelog entry must be after HardBounce
		hb_Date >= 'Mar 01, 2014' /* This is so we don;t start emailing 
								     someone from to long ago*/
-------------------------------------------------------------------------------
----------------Change HardBounce Value then Marketablebyemail-----------------
-------------------------------------------------------------------------------
--Update Hardbounce and MarketbleByEmail for all those in the previously created list
Update Relational.Customer
Set Hardbounced = 0,
	MarketableByEmail = 1
Where FanID in (Select Fanid from #NewEmail_Fans)

/***********************************************************************************************/
/*

	Author:		Stuart Barnley

	Date:		7th February 2017

	Purpose:	To populate a table for MyRewards Customers inidicating if 
				they live near a store for each active Merchant on the scheme.

*/

CREATE Procedure Staging.DriveTimePerMerchantPerCustomer
With Execute as Owner
As
------------------------------------------------------------------------
----------------------------Identify all Active Partners----------------
------------------------------------------------------------------------

Select	PartnerID,
		ROW_NUMBER() OVER(ORDER BY PartnerID ASC) AS RowNo
Into #Partners
From Relational.Partner as p
Where CurrentlyActive = 1 and
		BrandID is not null

Create clustered index cix_Partners_PartnerID on #Partners (PartnerID)

------------------------------------------------------------------------
----------------------------Identify all Active Customers----------------
------------------------------------------------------------------------

Select FanID,PostalSector
Into #Customers
From Relational.Customer as c
Where	CurrentlyActive =1
		

Create Clustered Index cix_Customers_FanID on #Customers (FanID)

------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------

Declare @RowNo int = 1, @RowNoMax int, @PartnerID  int

Create table #CustomersForAssessment (FanID int, PostalSector Varchar(6), primary key (FaniD))

Create table #MerchantPostcodes (PostalSector Varchar(6), primary key (PostalSector))

Create Table #Drivetimes (FanID int, MinDT Float, Primary Key (FanID))

Set @RowNoMax = (Select Max(RowNo) From #Partners)
While @RowNo <= @RowNoMax 
Begin
	Set @PartnerID = (Select PartnerID From #Partners where RowNo = @RowNo)
	
	----------------------------------------------------------------------------------
	-----------Find all Customers not alerady assessed with this partner--------------
	----------------------------------------------------------------------------------
	Insert into #CustomersForAssessment

	Select c.*
	From #Customers as c
	left Outer join Relational.DriveTimePerPartner as a
		on	c.FanID = a.FanID and
			@PartnerID = a.PartnerID
	Where a.FanID is null

	----------------------------------------------------------------------------------
	-----------------Find all Postal Sectors for the Merchants Stores-----------------
	----------------------------------------------------------------------------------
	--*******************
		--Deal with multi-record merchants (such as Caffe Nero)--
	--*******************
	Insert into #MerchantPostcodes
	
	Select Distinct o.PostalSector
	From Relational.Outlet as o
	inner join SLC_Report.dbo.RetailOutlet as RO
			on o.OutletID = ro.id
	Where	o.PartnerID = @PartnerID and
			SuppressFromSearch = 0
	----------------------------------------------------------------------------------
	---------------Find the minimum drive time per customers to a store---------------
	----------------------------------------------------------------------------------
	
	Insert into #Drivetimes

	Select c.FanID,Min(dtm.DriveTimeMins) as MinDT
	From #CustomersForAssessment as c
	inner join relational.DriveTimeMatrix as dtm
		on c.PostalSector = dtm.FromSector
	inner join #MerchantPostcodes as mp
		on dtm.ToSector = mp.PostalSector
	Group by c.FaniD

	----------------------------------------------------------------------------------
	----------------------------Insert the entries into the table---------------------
	----------------------------------------------------------------------------------

	Insert into Relational.DriveTimePerPartner 
	Select	c.FanID,
			@PartnerID,
			getdate() as RunDate,
			Case
				When dt.FanID is null then 0
				When dt.MinDT < 25 then 1
				Else 2
			End as DriveTime
	From #CustomersForAssessment as c
	Left Outer join #Drivetimes as dt
		on c.fanid = dt.fanid

	Truncate Table #CustomersForAssessment

	Truncate Table #MerchantPostcodes

	Truncate Table #Drivetimes

	Set @RowNo = @RowNo+1
End

--Select PartnerID,DriveTimeGroupID,Count(*) from Relational.DriveTimePerPartner  Group by PartnerID,DriveTimeGroupID
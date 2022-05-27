/*
	Author:		Stuart Barnley

	Date:		17th February 2016

	Purpose:	To return a list of Current Non-Core Merchants on the MyRewards Scheme



*/

CREATE Procedure Staging.Partner_MyRewards_NonCore_Current (@Type tinyint, @Month tinyint,@TableName varchar(200))

As

Declare @OffersSince Date,
		@Mths tinyint,
		@Qry nvarchar(Max)

Set @Mths = @Month 
Set @OffersSince = Dateadd(month,-@Mths,GetDate()) 

if object_id('tempdb..#Partners') is not null drop table #Partners
Create Table #Partners (PartnerID int,PartnerName varchar(50),Scheme_StartDate date, Primary Key(PartnerID))
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
Set @Qry = '

Insert Into #Partners 
Select	Distinct
		p.PartnerID,
		p.PartnerName,
		cbp.Scheme_StartDate
from Warehouse.relational.partner as p
inner join warehouse.relational.Partner_CBPDates as cbp
	on p.PartnerID = cbp.PartnerID'+
Case 
	When @Type = 2 Then
	'
	left outer join warehouse.relational.PartnerOffers_Base as pob
	on	p.PartnerID = pob.PartnerID and
		(pob.EndDate is null or pob.EndDate > Dateadd(day,DATEDIFF(dd, 0, GETDATE())-0,0) )
	'
	Else ''
End
 +
Case 
	When @Type = 3 Then
	'
	inner join warehouse.relational.PartnerOffers_Base as pob
	on	p.PartnerID = pob.PartnerID and
		(pob.EndDate is null or pob.EndDate > Dateadd(day,DATEDIFF(dd, 0, GETDATE())-0,0) )
	' Else '' End+ '
	Where (Scheme_EndDate is null or Scheme_EndDate > Dateadd(day,DATEDIFF(dd, 0, GETDATE())-0,0) )'+
Case
	When @Type = 2 then ' and pob.PartnerID is null' Else '' End
	+
'
Order by PartnerName
'
Exec sp_executeSQL @Qry

-----------------------------------------------------------------------------------------------------
--------------------------------------------Select Merchants-----------------------------------------
-----------------------------------------------------------------------------------------------------
Set @Qry = '
Select p.*,
		Max(Case
				When IsSignedOff = 1 and 
					 IsDefaultCollateral = 0 and 
					IsAboveTheLine = 0 and
					StartDate <= Dateadd(day,DATEDIFF(dd, 0, GETDATE())-0,0) Then StartDate
				Else NULL
			End) as LastLiveOffer,
		Min(Case
				When IsDefaultCollateral = 0 and 
					 IsAboveTheLine = 0 and
					StartDate > Dateadd(day,DATEDIFF(dd, 0, GETDATE())-0,0) Then StartDate
				Else NULL
			End) as NexOffer
Into '+@TableName+'
From #Partners as p
inner join warehouse.relational.ironoffer as i
	on p.PartnerID = i.PartnerID
Where StartDate >= '''+convert(varchar,@OffersSince,107)+'''
Group By p.PartnerID,p.PartnerName,	Scheme_StartDate
Order by PartnerName'

Exec sp_ExecuteSQL @Qry
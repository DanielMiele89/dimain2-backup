/*

	Author:		Stuart Barnley

	Date:		24th August 2015

	Purpose:	This process generates a set of data that is to be put in a CSV and sent to
				a mailing house so they can send out welcome packs

*/

CREATE Procedure Staging.DirectMail_CustomerList
as

Declare @StartDate date, @EndDate date,@Qry nvarchar(max)

Set @EndDate = Dateadd(day,-7,getdate())
Set @StartDate = Dateadd(day,-10,@EndDate)

Select @StartDate,@EndDate

---------------------------------------------------------------------------------
---------------------------Find new Debit Card Customers-------------------------
---------------------------------------------------------------------------------
if object_id('tempdb..#NewData') is not null drop table #NewData
select	c.FanID,
		Firstname,
		Lastname,
		Address1,
		Address2,
		City,
		County,
		Postcode,
		Description,
		Case
			When Coalesce(dd.ontrial,0) = 1 then 'Yes'
			Else 'No'
		End as Eligible,
		ActivatedDate,
		Case
			When clubid = 132 then 'NatWest'
			Else 'RBS'
		End as Bank
Into #NewData
From Warehouse.relational.customer as c
inner join warehouse.relational.CustomerPaymentMethodsAvailable as cp
	on	c.fanid = cp.FanID and
		cp.EndDate is null
inner join warehouse.relational.PaymentMethodsAvailable as pma
	on	cp.PaymentMethodsAvailableID = pma.PaymentMethodsAvailableID
Left Outer Join slc_report.dbo.FanSFDDailyUploadData_DirectDebit dd with (nolock)
	on c.fanid = dd.fanid
left outer join Warehouse.InsightArchive.Customers_NewDebitJoiners_MailHouse as a
	on c.fanid = a.fanid
where	ActivatedDate BEtween @StartDate and @EndDate and
		(ActivatedOffline = 1 or len(email) < 1 or email is null) and
		--pma.[Description] <> 'Both' and
		Address1 is not null and len(postcode) > 3 and
		a.fanid is null and
		pma.Description = 'Debit Card'
Order by Postcode

---------------------------------------------------------------------------------
---------------------------Find new Debit Card Customers-------------------------
---------------------------------------------------------------------------------

Set @Qry = ('
Select *
into Warehouse.InsightArchive.NewActivator_PostalAddressInfo_'+Convert(Varchar,getdate(),112)+'
From #NewData')

Exec SP_ExecuteSQL @Qry

Set @Qry = ('
Insert into Warehouse.InsightArchive.Customers_NewDebitJoiners_MailHouse
Select a.FanID,'''+CONVERT(char(10), GetDate(),126)+''' as DatetoMailingHouse 
from Warehouse.InsightArchive.NewActivator_PostalAddressInfo_'+Convert(Varchar,getdate(),112)+' as a')

Exec SP_ExecuteSQL @Qry

Set @Qry = ('
Select *
From Warehouse.InsightArchive.NewActivator_PostalAddressInfo_'+Convert(Varchar,getdate(),112))

Exec SP_ExecuteSQL @Qry
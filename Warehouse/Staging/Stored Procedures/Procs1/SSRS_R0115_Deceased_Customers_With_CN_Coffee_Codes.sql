/*

		Author:		Stuart Barnley

		Date:		25th January 2016

		Purpose:	To highlight anyone with a redemption code that is 
					marked in the system as deceased

*/

CREATE Procedure	[Staging].[SSRS_R0115_Deceased_Customers_With_CN_Coffee_Codes]
As
----------------------------------------------------------------------
----------------------------------------------------------------------
----------------------------------------------------------------------
if object_id('tempdb..#Deceased') is not null drop table #Deceased
Select ID as FanID,dob, Email,ClubID
Into #Deceased
From SLC_Report.dbo.fan
Where	AgreedTCs = 1 and
		AgreedTCsDate is not null and
		Status = 1 and
		DeceasedDate is not null
----------------------------------------------------------------------
----------------------------------------------------------------------
----------------------------------------------------------------------
Select	d.FanID as [Customer ID],
		Email,
		'' as CaffeNeroBirthdayCode,
		ClubID
Into #Customers
From #Deceased as d
inner join warehouse.Relational.RedemptionCode as rc
	on d.fanid = rc.FanID
Where	(
			(Month(DOB) = Month(GetDate())) 
				or
			(Month(GetDate()) < 12 and Month(GetDate())+1 = Month(DOB))
				or
			(Month(GetDate()) = 12 and  Month(DOB) = 1)
		) and 
		Len(Email) > 7 and
		Email like '%@%.%'
----------------------------------------------------------------------
----------------------------------------------------------------------
----------------------------------------------------------------------
Select * from #Customers
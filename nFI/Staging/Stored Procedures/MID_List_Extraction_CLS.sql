/*

	Author:		Stuart Barnley

	Date:		10th October 2016

	Purpose:	To produce a list of MerchantIDs to be provided to CLS

*/


CREATE Procedure [Staging].[MID_List_Extraction_CLS] (@PartnerID Int)
--With Execute as Owner
as

---------------------------------------------------------------------------------------------------
--------------------------Set Internal Parameter = to Partner ID-----------------------------------
---------------------------------------------------------------------------------------------------
Declare @PID int,@Rows smallint

Set @PID = @PartnerID

---------------------------------------------------------------------------------------------------
--------------------------------Produce table of MID entries---------------------------------------
---------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#t1') IS NOT NULL DROP TABLE #t1
Select	'20|REWARD INSIGHT|A|'+
		Cast(outletid as varchar(7))+
		'||||'+PartnerName+'|||'+
		Address1+
		Case
			When len(ltrim(Address2)) > 0 then ','+Address2
			Else ''
		End+'||'+
		City+'||||'+
		Postcode+'||GBR||||'+Ltrim(Rtrim(MerchantID))+'||'+
		'|||||'+CONVERT(VARCHAR(10), dateadd(day,-1,GETDATE()), 101)+'|||||||||'+CONVERT(VARCHAR(10), GETDATE(), 101) as A
Into #t1
From 
(
		Select	o.ID as OutletID,
				o.MerchantID,
				Replace(Address1,'|','') as Address1,
				Replace(Address2,'|','') as Address2,
				Replace(City,'|','') as City,
				Replace(Postcode,'|','') as Postcode,
				P.ID as PartnerID,
				p.Name as PartnerName
		from SLC_Report..RetailOutlet as o
		inner join SLC_Report..Fan as f
			on o.FanID = f.ID
		inner join SLC_Report..partner as p
	on o.PartnerID = p.ID
	Where p.ID = @PID
) as a

Set @Rows = (Select Count(*) From #t1)

---------------------------------------------------------------------------------------------------
-----------------------------Produce final data including header and footer------------------------
-----------------------------------------------------------------------------------------------------

Select '10|REWARD INSIGHT|'+ replace(convert(varchar(8), GetDate(), 112)+
											convert(varchar(8), Getdate(), 114), ':','')  as a
Union All
Select A from #t1
Union All
Select '30|REWARD INSIGHT|'+Cast(@Rows as  varchar) as a
/*

	Author:		Stuart Barnley

	Date:		10th October 2016

	Purpose:	To produce a list of MerchantIDs to be provided to CLS

*/


CREATE Procedure [Staging].[MID_List_Extraction_CLS_V1_1] (@PartnerID Int)
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
SELECT '20|REWARD INSIGHT|A|'+
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
INTO #t1
FROM (	SELECT ro.ID AS OutletID
			 , ro.MerchantID
			 , CASE
					WHEN ro.PartnerID IN (4723, 4637, 3432) AND LEN(REPLACE(fa.Address1,'|','')) > 0 AND LEN(REPLACE(ro.PartnerOutletReference,'|','')) > 5 THEN REPLACE(ro.PartnerOutletReference,'|','') + ', ' + REPLACE(fa.Address1,'|','')
					WHEN ro.PartnerID IN (4723, 4637, 3432) AND LEN(REPLACE(fa.Address1,'|','')) = 0 AND LEN(REPLACE(ro.PartnerOutletReference,'|','')) != 0 THEN REPLACE(ro.PartnerOutletReference,'|','')
					WHEN ro.PartnerID IN (4723, 4637, 3432) AND LEN(REPLACE(ro.PartnerOutletReference,'|','')) = 0 THEN REPLACE(fa.Address1,'|','')
					ELSE REPLACE(fa.Address1,'|','')
			   END AS Address1
			 , REPLACE(fa.Address2,'|','') AS Address2
			 , REPLACE(fa.City,'|','') AS City
			 , REPLACE(fa.Postcode,'|','') AS Postcode
			 , pa.ID as PartnerID
			 , pa.Name as PartnerName
		FROM SLC_Report..RetailOutlet ro
		INNER JOIN SLC_Report..Fan fa
			ON ro.FanID = fa.ID
		INNER JOIN SLC_Report..Partner pa
			ON ro.PartnerID = pa.ID
		WHERE pa.ID = @PID
		AND LEFT(LTRIM(ro.MerchantID), 1) NOT IN ('x', '#', 'A')) ro

Set @Rows = (Select Count(*) From #t1)

---------------------------------------------------------------------------------------------------
-----------------------------Produce final data including header and footer------------------------
---------------------------------------------------------------------------------------------------

Select '10|'+ replace(convert(varchar(8), GetDate(), 112)+
											convert(varchar(8), Getdate(), 114), ':','')+'|REWARD INSIGHT'  as a
Union All
Select A from #t1
Union All
Select '30|REWARD INSIGHT|'+Cast(@Rows as  varchar) as a
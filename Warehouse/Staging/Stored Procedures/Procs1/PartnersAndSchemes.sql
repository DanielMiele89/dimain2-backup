CREATE procedure [Staging].[PartnersAndSchemes]
as
begin

 --Insert matcher information in to temporary table
SELECT P.ID AS PartnerID,
              P.Name AS PartnerName,
              tv.Name AS Matcher,
              a.PartnerID AS SecondaryRecord,
              tv2.name AS SecondaryMatcher
INTO #Partners
FROM Warehouse.iron.PrimaryRetailerIdentification a
INNER JOIN SLC_Report..Partner p
       ON a.PrimaryPartnerID=p.ID
INNER JOIN SLC_Report..TransactionVector tv
       ON p.Matcher=tv.ID
INNER JOIN SLC_Report..Partner p2
       ON a.PartnerID=p2.ID
INNER JOIN SLC_Report..TransactionVector tv2
       ON p2.Matcher=tv2.id
WHERE PrimaryPartnerID IS NOT NULL

Select  
	p.partnername,
	case
	WHEN p.Matcher like 'Royal%' then 'RBS'
	when p.matcher like 'TNS%' or p.matcher like 'BMS%' or p.matcher like 'Elavon%' or p.matcher like 'CLS%' then 'nFI and RBS'
	when p.matcher like 'FDE%Lloyds%' then 'nFI'
	when p.matcher like 'Amex%' then 'Avios'
	end as [Matcher], p.partnerID,
	Case 
	when p.secondarymatcher like 'Royal%' then 'RBS'
	when p.secondarymatcher like 'TNS%' or p.secondarymatcher like 'BMS%' or p.secondarymatcher like 'Elavon%' or p.secondarymatcher like 'CLS%' then 'nFI and RBS'
	when p.secondarymatcher like 'Amex%' then 'Avios'
	Else 'Not Any'
	end as [secondarymatcher],
	p.secondaryrecord
Into #Matchers
from #Partners p

select 
	PartnerName,
	case
	when matcher like '%RBS%' then partnerID
	end as [rbs1],
	case
	when secondarymatcher like '%RBS%' then secondaryrecord
	end as [RBS2],
	case
	when matcher like '%nfi%' then partnerID
	end as [nfi1],
	case
	when secondarymatcher like '%nFI%' then secondaryRecord
	end as [nfi2],
	case 
	when secondarymatcher = 'Avios' then SecondaryRecord
	end as Avios
into #ResultsConcat
from #Matchers
order by partnername

--select * from #ResultsConcat

--Select	Replace(Replace(PartnerName,'(AMEX)',''),'(lloyds cardnet)','') as PartnerName,
--		Max(RBS) as RBS,
--		Max(nfi) as nFI, 
--		case 
--			When Max(nfi) is not null then Max(nFi)+ char(10) +Cast(Max(avios) as varchar)
--			When cast(Max(avios) as varchar) is not null then cast(Max(avios) as varchar) 
--			Else ''
--		End as [nFI_&_Amex]
--From (
--select partnername, 
----REPLACE(LTRIM(RTRIM(concat(rbs1, ' ' , rbs2))),' ',',') [RBS], -- commented and ammended to the below to include partner names
----REPLACE(LTRIM(RTRIM(concat(nfi1, ' ' , nfi2))),' ',',') [nfi], 
----avios,
--Case when convert(varchar(10), rbs1) is not null then convert(varchar(10), rbs1) +' - ' + pr1.Name else '' end +  
--Case when rbs2 is not null and rbs1 is not null then char(10) else '' end+
--Case When rbs2 is not null then convert(varchar(10), rbs2) + ' - ' +pr2.Name else '' End  as RBS,
--cast (nfi1 as varchar)+ ' - ' + pn1.Name +  
--Case when nfi2 is not null then Char(10)+cast (nfi2 as varchar) + ' - ' + pn2.Name else '' end as nFI,
--isnull(convert(varchar(10), avios) + ' - ' + pa.Name, '') as [Avios]

--from #resultsconcat r
--left join slc_report.dbo.Partner pr1 
--	on pr1.ID = r.rbs1
--left join slc_report.dbo.Partner pr2 
--	on pr2.ID = r.rbs2
--left join slc_report.dbo.Partner pn1 
--	on pn1.ID = r.nfi1
--left join slc_report.dbo.Partner pn2 
--	on pn2.ID = r.nfi2
--left join slc_report.dbo.Partner pa 
--	on pa.ID = r.Avios
--) as a
--Group by PartnerName
--ORDER BY PartnerName

--
--Truncate Table Drop table Warehouse.InsightArchive.PartnersAndSchemes
--Insert into Warehouse.InsightArchive.PartnersAndSchemes
Select	*,
		ROW_NUMBER() OVER(ORDER BY PartnerName DESC) AS RowNo
	Into #t1
from #resultsconcat


--Drop table #t2
Select	rbs1,
		PartnerName,
		RowNo
into #t2
from #t1 as a
Where rbs1 is not null
Union All
Select	rbs2,
		PartnerName,
		RowNo
from #t1 as a
Where rbs2 is not null
Union All
Select	nfi1,
		PartnerName,
		RowNo
from #t1 as a
Where nfi1 is not null
Union All
Select	nfi2,
		PartnerName,
		RowNo
from #t1 as a
Where nfi2 is not null
Union All
Select	Avios,
		PartnerName,
		RowNo
from #t1 as a
Where Avios is not null


Select Distinct RBS1,PartnerName,RowNo into #t3 from #t2

Select t.*,pb.BrandID
Into #t4
from #t3 as t
Left Outer join warehouse.mi.PartnerBrand as pb
	on t.rbs1 = pb.PartnerID

Update t
Set t.BrandID = t2.BrandID
From #t4 as t
inner join #t4 as t2
	on t.brandid is null and
		t2.BrandID is not null and
		t.RowNo = t2.RowNo 

Update t
Set t.BrandID = t2.BrandID
From #t4 as t
inner join #t4 as t2
	on t.brandid is null and
		t2.BrandID is not null and
		t.rbs1 = t2.rbs1 

Update t
Set t.BrandID = t2.BrandID
From #t4 as t
inner join #t4 as t2
	on t.brandid is null and
		t2.BrandID is not null and
		t.RowNo = t2.RowNo 
Truncate Table  Staging.PartnersVsBrands
Insert into Staging.PartnersVsBrands
Select Distinct RBS1 as PartnerID,
				Case
					When PartnerName like '%(%' then LEFT(PartnerName, CHARINDEX('(', PartnerName) - 1)
					Else PartnerName
				End AS PartnerName,
				--CHARINDEX('(', PartnerName),
				BrandID
from #t4
Order by BrandID

end

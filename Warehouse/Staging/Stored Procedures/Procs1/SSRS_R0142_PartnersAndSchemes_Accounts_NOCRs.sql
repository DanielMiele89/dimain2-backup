
CREATE procedure [Staging].[SSRS_R0142_PartnersAndSchemes_Accounts_NOCRs]
as
begin
SET NOCOUNT ON
 --Insert matcher information in to temporary table
SELECT P.ID AS PartnerID,
              Cast(P.Name as varchar(75)) AS PartnerName,
              tv.Name AS Matcher,
              a.PartnerID AS SecondaryRecord,
              tv2.name AS SecondaryMatcher
INTO #Partners
FROM Warehouse.iron.PrimaryRetailerIdentification_Accounts a
INNER JOIN SLC_Report..Partner p
       ON a.PrimaryPartnerID=p.ID
INNER JOIN SLC_Report..TransactionVector tv
       ON p.Matcher=tv.ID
INNER JOIN SLC_Report..Partner p2
       ON a.PartnerID=p2.ID
INNER JOIN SLC_Report..TransactionVector tv2
       ON p2.Matcher=tv2.id
WHERE PrimaryPartnerID IS NOT NULL
UNION
SELECT pri.PartnerID
	 , pa.Name as PartnerName
	 , tv.Name AS Matcher
	 , pri.PrimaryPartnerID AS SecondaryRecord
	 , tv2.Name AS SecondaryMatcher
FROM iron.PrimaryRetailerIdentification_Accounts pri
INNER JOIN SLC_Report..Partner pa
       ON pri.PartnerID = pa.ID
INNER JOIN SLC_Report..TransactionVector tv
       ON pa.Matcher = tv.ID
LEFT JOIN SLC_Report..Partner p2
       ON pri.PrimaryPartnerID = p2.ID
LEFT JOIN SLC_Report..TransactionVector tv2
       ON p2.Matcher = tv2.id
WHERE NOT EXISTS (Select 1
				  From iron.PrimaryRetailerIdentification_Accounts pri2
				  Where pri.PartnerID = pri2.PrimaryPartnerID)
And pri.PrimaryPartnerID Is Null




Select  
	p.partnername,
	case
	WHEN p.Matcher like 'Royal%' then 'nFI and RBS'
	when p.matcher like 'TNS%' or p.matcher like 'BMS%' or p.matcher like 'Elavon%' or p.matcher like 'Mastercard%' then 'nFI and RBS'
	when p.matcher like 'FDE%Lloyds%' then 'nFI'
	when p.matcher like 'Amex%' then 'Avios'
	end as [Matcher], p.partnerID,
	Case 
	WHEN p.secondarymatcher like 'Royal%' then 'nFI and RBS'
	when p.secondarymatcher like 'TNS%' or p.secondarymatcher like 'BMS%' or p.secondarymatcher like 'Elavon%' or p.secondarymatcher like 'Mastercard%' then 'nFI and RBS'
	when p.secondarymatcher like 'Amex%' then 'Avios'
	when p.secondarymatcher like 'FDE%Lloyds%' then 'nFI'
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
	When Matcher = 'Avios' Then PartnerID
	end as Avios
into #ResultsConcat
from #Matchers
order by partnername

--select * from #Matchers


Select	Replace(Replace(PartnerName,'(AMEX)',''),'(lloyds cardnet)','') as PartnerName,
		Max(RBS) as RBS,
		Max(nfi) as nFI, 
		case 
			When Max(nfi) is not null then Max(nFi)+ CASE WHEN MAX(Avios) = '' THEN '' ELSE '\n' +Cast(Max(avios) as varchar(45)) END
			When cast(Max(avios) as varchar) is not null then cast(Max(avios) as varchar(45)) 
			Else ''
		End as [nFI_&_Amex]
From (
		select partnername, 
		--REPLACE(LTRIM(RTRIM(concat(rbs1, ' ' , rbs2))),' ',',') [RBS], -- commented and ammended to the below to include partner names
		--REPLACE(LTRIM(RTRIM(concat(nfi1, ' ' , nfi2))),' ',',') [nfi], 
		--avios,
		Case when convert(varchar(10), rbs1) is not null then convert(varchar(10), rbs1) +' - ' + pr1.Name else '' end +  
		Case when rbs2 is not null and rbs1 is not null then ',' else '' end+
		Case When rbs2 is not null then convert(varchar(10), rbs2) + ' - ' +pr2.Name else '' End  as RBS,
		cast (nfi1 as varchar)+ ' - ' + pn1.Name +  
		Case when nfi2 is not null then ','+cast (nfi2 as varchar) + ' - ' + pn2.Name else '' end as nFI,
		isnull(convert(varchar(10), avios) + ' - ' + pa.Name, '') as [Avios]
		from #resultsconcat r
		left join slc_report.dbo.Partner pr1 
			on pr1.ID = r.rbs1
		left join slc_report.dbo.Partner pr2 
			on pr2.ID = r.rbs2
		left join slc_report.dbo.Partner pn1 
			on pn1.ID = r.nfi1
		left join slc_report.dbo.Partner pn2 
			on pn2.ID = r.nfi2
		left join slc_report.dbo.Partner pa 
			on pa.ID = r.Avios
		) as a
Group by PartnerName
ORDER BY PartnerName


END

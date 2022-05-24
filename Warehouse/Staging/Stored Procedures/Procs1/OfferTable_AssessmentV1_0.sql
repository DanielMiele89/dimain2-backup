CREATE Procedure [Staging].[OfferTable_AssessmentV1_0] @TableName varchar(400)
as

Declare @Qry nvarchar(max)--,@TableName varchar(400)
--Set @TableName = 'Sandbox.[Stuart].[CT004_CharlesTyrwhittSelection]'
-------------------------------------------------------------------------------------------
----------------------If table already assessed remove previous output---------------------
-------------------------------------------------------------------------------------------

Delete from Warehouse.Staging.OfferTable_Assessment Where TableName = @TableName
-------------------------------------------------------------------------------------------
------------------------Assess Data File including HTM and Partner-------------------------
-------------------------------------------------------------------------------------------
Set @Qry = 
'
if object_id(''Sandbox.'+SUSER_NAME()+'.OfferFileAssessmentPart1'') is not null drop table Sandbox.'+SUSER_NAME()+'.OfferFileAssessmentPart1
Select	*, 
		Round(Cast([Control] as real)/([Control]+[Mail]),2) as [Control%]
into Sandbox.'+SUSER_NAME()+'.OfferFileAssessmentPart1
from 
(select	i.IronOfferID,
		i.IronOfferName,
		Cast(i.StartDate as Date) as StartDate,
		Cast(i.EndDate as Date) as EndDate,
		p.PartnerID,
		p.PartnerName,
		g.htmid,
		Case
			When g.HTM_Description = ''Not Eligible'' then ''Irregular Spenders''
			Else g.HTM_Description
		End as HTMDescription,
		Count(*) as CustomerCount,
		Sum(Case
				When a.Grp = ''Mail'' then 1
				Else 0
			End) as Mail,
		Sum(Case
				When a.Grp = ''Control'' then 1
				Else 0
			End) as [Control]
from '+@TableName+ ' as a
inner join warehouse.relational.IronOffer as i
	on a.OfferID = i.IronOfferID
inner join warehouse.relational.Partner as p
	on i.PartnerID = p.PartnerID
Left Outer join Warehouse.Relational.HeadroomTargetingModel_Members as HTM
	on p.PartnerID = htm.PartnerID and a.FanID = htm.FanID and htm.EndDate is null
left outer join Warehouse.relational.HeadroomTargetingModel_Groups as g
	on HTM.HTMID = g.HTMID
Group by	i.IronOfferID, i.IronOfferName,Cast(i.StartDate as Date),Cast(i.EndDate as Date),p.PartnerID,p.PartnerName,g.htmid,
		Case
			When g.HTM_Description = ''Not Eligible'' then ''Irregular Spenders''
			Else g.HTM_Description
		End
) as a'

--Select @Qry
Exec sp_ExecuteSQL @Qry
-------------------------------------------------------------------------------------------
--------------------------------Pull Possible Customer Counts------------------------------
-------------------------------------------------------------------------------------------
Set @Qry = '
if object_id(''Sandbox.'+SUSER_NAME()+'.OfferFileAssessmentPart2'') is not null drop table Sandbox.'+SUSER_NAME()+'.OfferFileAssessmentPart2
select	htm.PartnerID,
		htm.HTMID,
		Count(*) as CustomerCount,
		Sum(Case
				When Rainbow_Customer = 0 then 1
				Else 0
			End) as NonRainbow
into Sandbox.'+SUSER_NAME()+'.OfferFileAssessmentPart2
from Warehouse.Relational.HeadroomTargetingModel_Members as htm
inner join Warehouse.Relational.Customer as c
	on htm.FanID = c.FanID and htm.EndDate is null
Left outer join Warehouse.Relational.SmartFocusUnSubscribes as sfu
	on htm.fanid = sfu.fanid and sfu.enddate is null
inner join Sandbox.'+SUSER_NAME()+'.OfferFileAssessmentPart1 as a
	on htm.PartnerID = a.PartnerID and htm.htmid = a.HTMID
Where MarketablebyEmail = 1 and sfu.fanid is null and len(c.Postcode) >= 3 and CurrentlyActive = 1
Group by htm.PartnerID,htm.HTMID'
--Select @Qry
Exec sp_ExecuteSQL @Qry

-------------------------------------------------------------------------------------------
-----------------------------------------Combine Together----------------------------------
-------------------------------------------------------------------------------------------
Set @Qry = '
Insert Into Warehouse.Staging.OfferTable_Assessment
select	A.IronOfferID,
		A.IronOfferName,
		A.StartDate,
		A.EndDate,
		A.PartnerName,
		A.HTMDescription,
		A.CustomerCount,
		A.Mail,
		A.[Control],
		A.[Control%],
		B.CustomerCount as PossibleCustomerCount,
		B.NonRainbow,
		getdate() as RunDate,
		'''+@TableName+''' as TableName
from Sandbox.'+SUSER_NAME()+'.OfferFileAssessmentPart1 as A
inner join Sandbox.'+SUSER_NAME()+'.OfferFileAssessmentPart2 as B
	on	A.PartnerID = B.PartnerID and
		A.HTMID = B.HTMID
Order by IronOfferID'
--Select @Qry
Exec sp_ExecuteSQL @Qry
-------------------------------------------------------------------------------------------
----------------------------------------Drop interim tables--------------------------------
-------------------------------------------------------------------------------------------
Set @Qry = 
'Drop table Sandbox.'+SUSER_NAME()+'.OfferFileAssessmentPart1
 Drop table Sandbox.'+SUSER_NAME()+'.OfferFileAssessmentPart2
'
Exec sp_ExecuteSQL @Qry
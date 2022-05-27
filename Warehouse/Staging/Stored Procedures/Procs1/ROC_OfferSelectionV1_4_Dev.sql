CREATE Procedure [Staging].[ROC_OfferSelectionV1_4_Dev]	(	
						@PartnerID int, 
						@Wave int, 
						@IOM_Check bit,
						@TableName varchar(150),
						@ControlTable varchar(150)
												)
As


--Declare @PartnerID int,@Wave int, @IOM_Check bit
--Set @PartnerID = 4319
--Set @Wave = 1
--Set @IOM_Check = 0

Declare @StartDate date
Set @StartDate = (Select StartDate From Relational.ROC_WaveDates where ID = @Wave)

if object_id('tempdb..#Settings') is not null drop table #Settings
Create table #Settings (PartnerID int not null, 
						StartDate Date not null,
						CtrlGrp int not null,
						IOM_Check bit not null,
						Tablename Varchar(150),
						ControlTable varchar(150)
					   )

Insert Into #Settings
Select	@PartnerID as PartnerID, 
		@StartDate as StartDate, 
		(	Select CtrlGrp 
			from Staging.ROC_Segmentation_PartnerSettings 
			where PartnerID = @PartnerID
		) as CtrlGrp,
		@IOM_Check as IOM_Check,
		@TableName as TableName,
		@ControlTable as ControlTable

Select * from  #Settings

--------------------------------------------------------------------------------------------
-----------------------Select Offers that need to be populated------------------------------
--------------------------------------------------------------------------------------------
if object_id('tempdb..#Offers') is not null drop table #Offers
Select	PartnerID,
		IronOfferID,
		SegmentID
Into #Offers
From Staging.ROC_Segmentation_Offers
Where PartnerID = (Select PartnerID from #Settings) and CurrentOffer = 1
Union All
Select	o.PartnerID,
		o.IronOfferID,
		SegmentID
from Warehouse.iron.PrimaryRetailerIdentification as a
inner join Staging.ROC_Segmentation_Offers as o
	on a.PartnerID = o.PartnerID
Where PrimaryPartnerID = (Select PartnerID from #Settings)

--------------------------------------------------------------------------------------------
---------------------Select Customers that need to be added as members----------------------
--------------------------------------------------------------------------------------------

if object_id('tempdb..#OfferMembers') is not null drop table #OfferMembers
Select	o.IronOfferID,
		f.CompositeID,
		f.ID as FanID,
		m.SegmentID
into #OfferMembers
from #Offers as o
inner join staging.ROC_Segmentation_Members as m
	on	m.SegmentID = o.SegmentID and
		o.PartnerID = m.PartnerID and
		m.EndDate IS null
inner join slc_report.dbo.Fan as f
	on	m.FanID = f.ID

--------------------------------------------------------------------------------------------
-------------------------------Assign Members to IronOfferIDs-------------------------------
--------------------------------------------------------------------------------------------

if object_id('tempdb..#OfferMembersIDs') is not null drop table #OfferMembersIDs
Create Table #OfferMembersIDs (	RowNo int not null, 
								FanID int not null, 
								CompositeID bigint not null,
								IronOfferID int not null,
								StartDate Date not null,
								EndDate Date null,
								[Date] date not null,
								IsControl bit not null,
								SegmentID smallint not null)
Declare @Qry nvarchar(max)

Set @Qry = '

Insert into #OfferMembersIDs
Select	ROW_NUMBER() OVER(PARTITION BY f.IronOfferID ORDER BY NewID() DESC) AS RowNo,
		f.FanID,
		f.CompositeID,
		f.IronOfferID,
		StartDate = (Select StartDate from #Settings),
		NULL as EndDate,
		GETDATE() as date,
		0 as IsControl,
		f.SegmentID
from #OfferMembers as f'+ 
Case
	When (Select IOM_Check from #Settings) = 1 Then 
'
Left Outer join SLC_Report.dbo.IronOfferMember as iom With (Nolock)
	on	f.CompositeID = iom.CompositeID and
		f.IronOfferID = iom.IronOfferID and
		iom.EndDate is null
Where iom.CompositeID is null
' Else ''
End
Exec sp_ExecuteSQL @Qry

--------------------------------------------------------------------------------------------
--------------------------------Ascertain Control Group Splits------------------------------
--------------------------------------------------------------------------------------------
if object_id('tempdb..#Splits') is not null drop table #Splits
Select	IronOfferID, 
		Count(*) as TotalMembers,
		(cast(Count(*) as real)/100) * (Select CtrlGrp from #Settings) ControlGroup
Into #Splits
from #OfferMembersIDs as a
Group by IronOfferID
--------------------------------------------------------------------------------------------
-------------------------------Allocate Control Group Membership----------------------------
--------------------------------------------------------------------------------------------
if object_id('tempdb..#OfferSelection') is not null drop table #OfferSelection
Create table #OfferSelection (FanID int,CompositeID bigint,IronOfferID int,StartDate Date,EndDate Date,[Date] Date,IsControl bit,SegmentID int,Primary Key (FanID))

if Len(@ControlTable) = 0 --- if creating new control group
Begin
	Insert Into #OfferSelection
	Select	a.FanID,
			a.CompositeID,
			a.IronOfferID,
			StartDate = (Select StartDate from #Settings),
			NULL as EndDate,
			GETDATE() as date,
			Case
				When a.RowNo < s.ControlGroup then 1
				Else 0 
			End as IsControl,
			a.SegmentID
	From #OfferMembersIDs as a
	inner join #Splits as s
		on a.IronOfferID = s.IronOfferID
End

If Len(@ControlTable) > 0 --- if using existing control group
Begin
	Set @Qry = '
	Insert Into #OfferSelection
	Select	a.FanID,
			a.CompositeID,
			a.IronOfferID,
			StartDate = (Select StartDate from #Settings),
			NULL as EndDate,
			GETDATE() as date,
			Coalesce(b.IsControl,0) as IsControl,
			a.SegmentID
	From #OfferMembersIDs as a
	Left Outer join (Select Distinct CompositeID, IsControl From '+@ControlTable+') as b
		on	a.CompositeID = b.CompositeID'

	Exec sp_ExecuteSQL @Qry
End

--------------------------------------------------------------------------------------------
------------------------------Add Members to subsequent brand offers------------------------
--------------------------------------------------------------------------------------------
Insert Into #OfferSelection
Select	a.FanID,
		a.CompositeID,
		b.IronOfferID,
		a.StartDate,
		a.EndDate,
		a.[Date],
		a.IsControl,
		a.SegmentID
from #OfferSelection as a
inner join #Offers as b
	on a.SegmentID = b.SegmentID	
Where PartnerID <> (Select PartnerID from #Settings)

--------------------------------------------------------------------------------------------
-------------------------------------Double check counts------------------------------------
--------------------------------------------------------------------------------------------
Select	
		i.PartnerID,
		p.Name as PartnerName,
		IronOfferID,
		i.Name as OfferName,
		i.StartDate,
		i.EndDate,
		SegmentDescription,
		Sum(Case
				When IsControl = 0 then 1
				When IsControl = 1 then 0
			End) as Mail,
		Sum(Cast(IsControl as int)) as Ctrl,
		Cast(Sum(Cast(IsControl as int)) as real)/Count(*) as [Ctrl%],
		s.StartDate as Member_StartDate
from #OfferSelection as s
inner join slc_report.dbo.IronOffer as i
	on s.IronOfferID = i.id
inner join slc_report.dbo.Partner as p
	on i.PartnerID = p.ID
inner join Warehouse.Staging.ROC_Segmentation_Descriptions as d
	on s.SegmentID = d.SegmentID
Group By i.PartnerID,p.Name,IronOfferID,i.Name,SegmentDescription,i.StartDate,i.EndDate,s.StartDate
Order by IronOfferID,SegmentDescription

--------------------------------------------------------------------------------------------
-------------------------------------Create Final Selection Table---------------------------
--------------------------------------------------------------------------------------------
Declare @IndexName_Part1 varchar (100)
--Set @TableName = 'Sandbox.Stuart.CaffeNeroSelection_ROC'
Set @IndexName_Part1 = Right(@TableName,Len(@TableName) -CHARINDEX('.',@TableName))
Set @IndexName_Part1 = Right(@TableName,Len(@IndexName_Part1) -CHARINDEX('.',@IndexName_Part1))
--Select @IndexName_Part1

Set @Qry = '
Select *
Into '+ @TableName +'
From #OfferSelection

--Create Clustered Index IX_'+@IndexName_Part1+'_IronOfferID_IsControl on '+@TableName+' (IronOfferID,IsControl)
--Create NonClustered Index IX_'+@IndexName_Part1+'_FanID on '+@TableName+' (FanID)'


Exec sp_ExecuteSQL @Qry
--Select @Qry

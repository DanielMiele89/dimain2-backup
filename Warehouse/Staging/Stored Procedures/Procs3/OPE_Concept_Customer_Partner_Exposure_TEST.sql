CREATE Procedure [Staging].[OPE_Concept_Customer_Partner_Exposure_TEST] (@EmailDate Date)
As

Set NoCount on
Declare @Local_Date date
Set @Local_Date = @EmailDate
--Declare @Local_Date Date
--Set @Local_Date = 'Nov 06, 2014'
-------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------ Build Customer Table ---------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------
if object_id('tempdb..#Customer') is not null drop table #Customer
Select 	--Top 2501
		FanID, 
		ROW_NUMBER() OVER(ORDER BY FanID Asc) AS RowNo
Into #Customer
from Relational.Customer as c

-------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------ Create table to put final scores in ------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------
--if object_id('Staging.OPE_Customer_Customer_Partner_Exposure') is not null 
--									drop table Staging.OPE_Customer_Customer_Partner_Exposure
									
--Create Table Staging.OPE_Customer_Customer_Partner_Exposure (id int identity(1,1), 
--															 FanID int,
--															 PartnerID int, 
--															 Score tinyint,
--															 Primary Key (ID)
--															)
--Create NonClustered Index idx_OPE_Customer_Customer_Partner_Exposure_FanIDPartnerID 
--									on Staging.OPE_Customer_Customer_Partner_Exposure (FanID,PartnerID)
Truncate table Staging.OPE_Customer_Customer_Partner_Exposure
-------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------Create table to hold counts of exposures-------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------
Declare @Qry nvarchar(Max),@PartnerID nvarchar(max)

if object_id('Staging.OPE_Customer_Partner_Exposure') is not null 
									drop table Staging.OPE_Customer_Partner_Exposure
									
Set @PartnerID = (Select '['+Cast(PartnerID as varchar)+'] tinyint,' as 'text()'from Relational.Partner Order by PartnerID for xml path(''))

Set @Qry = 'Create Table Staging.OPE_Customer_Partner_Exposure (FanID int,'+ LEFT(@PartnerID,LEN(@PartnerID)-1)+')'

--Select  @Qry

Exec sp_ExecuteSQL @Qry

----------------------------------------------------------------------
if object_id('tempdb..#PartnerExposure') is not null drop table #PartnerExposure

Create Table #PartnerExposure (
								id int identity(1,1), 
								FanID int,
								PartnerID int, 
								ExposureDate Date,
								Slot int, 
								Primary key (id)
							  
							  )
Create nonclustered index idx_PartnerExposure_FanID 
								on #PartnerExposure (FanID)
								
Create nonclustered index idx_PartnerExposure_PartnerID 
								on #PartnerExposure (PartnerID)

Declare @RowNo int, @Chunk int,@RowEnd int
Set @RowNo = 1
Set @Chunk = 2500
While @RowNo <= (Select MAX(RowNo) from #Customer as c)
Begin
	Set @RowEnd = @RowNo+@Chunk-1
	-----------------------Pull FanID vs. PartnerID in Slot1------------------------------
	Insert Into #PartnerExposure
	Select	[Customer ID] as FanID,
			p.PartnerID,
			[Last Loaded Date] as ExposureDate,
			1 as slot
	from Relational.SFD_PostUploadAssessmentData_TEST as s
	inner join relational.IronOffer as i
		on s.Offer1 = i.IronOfferID
	inner join relational.Partner as p
		on i.PartnerID = p.PartnerID
	inner join #Customer as c
		on s.[Customer ID] = c.FanID
	Where c.RowNo between @RowNo and @RowEnd and
			[Last Loaded Date] > Dateadd(day,-37,@Local_Date) --and 
			--FanID = 1959404
	Union All
	-------------------------Pull FanID vs. PartnerID in Slot2------------------------------
	--Insert Into #PartnerExposure
	Select 	[Customer ID] as FanID,
			p.PartnerID,
			[Last Loaded Date] as ExposureDate,
			2 as slot
	from Relational.SFD_PostUploadAssessmentData_TEST as s
	inner join relational.IronOffer as i
		on s.Offer2 = i.IronOfferID
	inner join relational.Partner as p
		on i.PartnerID = p.PartnerID
	inner join #Customer as c
		on s.[Customer ID] = c.FanID
	Where c.RowNo Between @RowNo and @RowEnd and
			[Last Loaded Date] > Dateadd(day,-37,@Local_Date)
	Union All		
	-------------------------Pull FanID vs. PartnerID in Slot3------------------------------
	
	--Insert Into #PartnerExposure
	Select 	[Customer ID] as FanID,
			p.PartnerID,
			[Last Loaded Date] as ExposureDate,
			3 as slot
	from Relational.SFD_PostUploadAssessmentData_TEST as s
	inner join relational.IronOffer as i
		on s.Offer3 = i.IronOfferID
	inner join relational.Partner as p
		on i.PartnerID = p.PartnerID
	inner join #Customer as c
		on s.[Customer ID] = c.FanID
	Where c.RowNo Between @RowNo and @RowEnd and
			[Last Loaded Date] > Dateadd(day,-37,@Local_Date)
	Union All
	-------------------------Pull FanID vs. PartnerID in Slot4------------------------------
	--Insert Into #PartnerExposure
	Select 	[Customer ID] as FanID,
			p.PartnerID,
			[Last Loaded Date] as ExposureDate,
			4 as slot
	from Relational.SFD_PostUploadAssessmentData_TEST as s
	inner join relational.IronOffer as i
		on s.Offer4 = i.IronOfferID
	inner join relational.Partner as p
		on i.PartnerID = p.PartnerID
	inner join #Customer as c
		on s.[Customer ID] = c.FanID
	Where c.RowNo Between @RowNo and @RowEnd and
			[Last Loaded Date] > Dateadd(day,-37,@Local_Date)
	Union All
	-------------------------Pull FanID vs. PartnerID in Slot5------------------------------
	--Insert Into #PartnerExposure
	Select 	[Customer ID] as FanID,
			p.PartnerID,
			[Last Loaded Date] as ExposureDate,
			5 as Slot
	from Relational.SFD_PostUploadAssessmentData_TEST as s
	inner join relational.IronOffer as i
		on s.Offer5 = i.IronOfferID
	inner join relational.Partner as p
		on i.PartnerID = p.PartnerID
	inner join #Customer as c
		on s.[Customer ID] = c.FanID
	Where c.RowNo Between @RowNo and @RowEnd and
			[Last Loaded Date] > Dateadd(day,-37,@Local_Date)
	Union All
	-------------------------Pull FanID vs. PartnerID in Slot6------------------------------
	--Insert Into #PartnerExposure
	Select 	[Customer ID] as FanID,
			p.PartnerID,
			[Last Loaded Date] as ExposureDate,
			6 as slot
	from Relational.SFD_PostUploadAssessmentData_TEST as s
	inner join relational.IronOffer as i
		on s.Offer6 = i.IronOfferID
	inner join relational.Partner as p
		on i.PartnerID = p.PartnerID
	inner join #Customer as c
		on s.[Customer ID] = c.FanID
	Where c.RowNo Between @RowNo and @RowEnd and
			[Last Loaded Date] > Dateadd(day,-37,@Local_Date)
	Union All
	-----------------------Pull FanID vs. PartnerID in Slot7------------------------------
	--Insert Into #PartnerExposure
	Select 	[Customer ID] as FanID,
			p.PartnerID,
			[Last Loaded Date] as ExposureDate,
			7 as slot
	from Relational.SFD_PostUploadAssessmentData_TEST as s
	inner join relational.IronOffer as i
		on s.Offer7 = i.IronOfferID
	inner join relational.Partner as p
		on i.PartnerID = p.PartnerID
	inner join #Customer as c
		on s.[Customer ID] = c.FanID
	Where c.RowNo Between @RowNo and @RowEnd and
			[Last Loaded Date] > Dateadd(day,-37,@Local_Date)
	
-------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------Create a table of Customer vs. Partner Exposure-----------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------	
	Set @Qry =
	'Insert into Staging.OPE_Customer_Partner_Exposure
	Select fanid, '+left(Replace(@PartnerID,' tinyint',''),LEN(Replace(@PartnerID,' tinyint',''))-1)+'
		From
	(select c.FanID,PartnerID
	from #Customer as c
	left outer join #PartnerExposure as p
		on c.FanID = p.FanID	
	Where c.RowNo between '+cast(@RowNo as varchar)+' and '+cast(@RowEnd as varchar)+'
	) as a
	Pivot
	(Count(PartnerID)
	For PartnerID in ('+left(Replace(@PartnerID,' tinyint',''),LEN(Replace(@PartnerID,' tinyint',''))-1)+')
	) as Pvt
	Order by FanID'
	
	Exec sp_executeSQL @qry

-------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------Create final table of Customer vs. Partner Scores (minus 100 points)--------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------
	
	Set @Qry = 
'   Insert into Staging.OPE_Customer_Customer_Partner_Exposure
	Select  Distinct
			FanID,
			PartnerID,
			Score
	 From
		(Select FanID,PartnerID,Exposures
			From
				(Select *
				From Staging.OPE_Customer_Partner_Exposure) as p
			UNPIVOT
			(Exposures FOR PartnerID IN ('+left(Replace(@PartnerID,' tinyint',''),LEN(Replace(@PartnerID,' tinyint',''))-1)+')
			)AS unpvt
		) as a
	Left Outer join Staging.OPE_ConceptScore as cs
		on a.Exposures = Cast(cs.Value as tinyint)
	Where ConceptID = 9 and Exposures > 0
	'
	
	--Select @Qry
	Exec sp_executeSQL @Qry
	Truncate Table Staging.OPE_Customer_Partner_Exposure
	
	Set @RowNo = @RowNo+@Chunk
End

/*
 Author:			Stuart Barnley
 Date:				05/12/2014

 Description:		This stored procedure creates the Outlet table

 Notes:

*/

Create Procedure [Staging].[PennyforLondon_Outlet]
as
Begin

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into Relational.JobLog_Temp
Select	StoredProcedureName = 'Penny4London_Outlet',
		TableSchemaName = 'Relational',
		TableName = 'Outlet',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'

/*--------------------------------------------------------------------------------------------------
-----------------------------Create Transport for London MID----------------------------------------
----------------------------------------------------------------------------------------------------*/
Truncate Table Relational.Outlet
Insert into	Relational.Outlet
select	0 as OutletID,
		'' as MerchantID,
		0 as PartnerID,
		'' as Address1,
		'' as Address2,
		'' as City,
		'' as Postcode,
		'' as PostalSector,
		'' as PostArea,
		'' as Region


----------------------------------------------------------------------------------------
------------------------------Populate Outlet table-------------------------------------
----------------------------------------------------------------------------------------
Insert into	Relational.Outlet
select	ro.ID as OutletID,
		ro.MerchantID,
		ro.PartnerID,
		LTRIM(RTRIM(f.Address1))				as Address1,
		LTRIM(RTRIM(f.Address2))				as Address2,
		LTRIM(RTRIM(f.City))					as City,		
		LEFT(ltrim(rtrim(f.PostCode)),10)		as Postcode,
		Cast(Null as varchar(6))				as PostalSector,
		Cast(Null as varchar(2))				as PostArea,
		Cast(Null as varchar(30))				as Region
from	SLC_Report.dbo.RetailOutlet ro with (nolock)
		left join SLC_Report.dbo.Fan f with (nolock) on ro.FanID = f.ID
		inner join Relational.Partner p with (nolock) on ro.PartnerID = p.PartnerID
Where	p.PartnerID > 0

update Relational.Outlet
set	PostalSector =	
			Case
				When replace(replace(PostCode,char(160),''),' ','') like '[a-z][0-9][0-9][a-z][a-z]' Then
					 Left(replace(replace(PostCode,char(160),''),' ',''),2)+' '+Right(Left(replace(replace(PostCode,char(160),''),' ',''),3),1)
				When replace(replace(PostCode,char(160),''),' ','') like '[a-z][0-9][0-9][0-9][a-z][a-z]' or
					 replace(replace(PostCode,char(160),''),' ','') like '[a-z][a-z][0-9][0-9][a-z][a-z]' or 
					 replace(replace(PostCode,char(160),''),' ','') like '[a-z][0-9][a-z][0-9][a-z][a-z]' Then 
					 Left(replace(replace(PostCode,char(160),''),' ',''),3)+' '+Right(Left(replace(replace(PostCode,char(160),''),' ',''),4),1)
				When replace(replace(PostCode,char(160),''),' ','') like '[a-z][a-z][0-9][0-9][0-9][a-z][a-z]' or
					 replace(replace(PostCode,char(160),''),' ','') like '[a-z][a-z][0-9][a-z][0-9][a-z][a-z]'Then 
					 Left(replace(replace(PostCode,char(160),''),' ',''),4)+' '+Right(Left(replace(replace(PostCode,char(160),''),' ',''),5),1)
				Else ''
			End,
	PostArea =		
			case 
				when PostCode like '[A-Z][0-9]%' then left(PostCode,1) 
				else left(PostCode,2) 
			end

update	Relational.Outlet
set		Region = pa.Region
from	Relational.Outlet as o
inner join Relational.PostArea as pa
	on o.PostArea = pa.PostAreaCode


/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  Relational.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'Penny4London_Outlet' and
		TableSchemaName = 'Relational' and
		TableName = 'Outlet' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
-----------------------------Update entry in JobLog Table with Row Count------------------------------
------------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  Relational.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.Outlet)
where	StoredProcedureName = 'Penny4London_Outlet' and
		TableSchemaName = 'Relational' and
		TableName = 'Outlet' and
		TableRowCount is null


Insert into Relational.JobLog
select	[StoredProcedureName],
		[TableSchemaName],
		[TableName],
		[StartDate],
		[EndDate],
		[TableRowCount],
		[AppendReload]
from Relational.JobLog_Temp

truncate table Relational.JobLog_Temp
End
CREATE Procedure [Staging].[ForecastV0_1_Prototype] (
				@ForcastType tinyint,
				@PartnerID Int,
				@Brands varchar(100),
				@Trans_StartDate varchar(10),
				@Trans_EndDate varchar(10),
				@Lapse1Date varchar(10),
				@Lapse1Name varchar(35),
				@Lapse2Date varchar(10),
				@Lapse2Name varchar(35)
				)
				as

Declare @Part1 nvarchar(max),@CC_IDs nvarchar(max)

Set @Part1 = '
/*----------------------------------------------------------------------------------------

	Author:			Stuart Barnley
	SP Create Date: 05th February 2015
	SP Name:		ForcastV0_1_Prototype

	Executed by: '+ User_Name() + '
	Selection Date: '+ Convert(varchar, getdate(), 110) + '
	
	Purpose:		To create a set of code to pull a forecast based on defined parameters

*/----------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
--------------Create Table of Currently Active Marketable CB+ Customers-------------
------------------------------------------------------------------------------------

Select CinID 
Into #Customers
from Relational.Customer as c with (nolock)
inner join Relational.CinList as cl with (nolock)
	on c.SourceUID = cl.Cin
Left Outer join Staging.Customer_DuplicateSourceUID as s with (nolock)
	on c.SourceUID = s.SourceUID
Where	c.CurrentlyActive = 1 and
		c.MarketableByEmail = 1 and
		s.SourceUID is null

Create Index IDX_Customers_CINID on #Customers (CINID)
'

------------------------------------------------------------------------------------
-----------------------------Get ConsumerCombinationIDs-----------------------------
------------------------------------------------------------------------------------

If @ForcastType = 0
Begin

Set @CC_IDs = '
------------------------------------------------------------------------------------
-------------------------Get ConsumerCombinationIDs for the Brand-------------------
------------------------------------------------------------------------------------

Select	ConsumerCombinationID,
		p.BrandID,
		''Partner'' as [Type]
Into #CCIDs
from Warehouse.Relational.Partner as p with (nolock)
inner join Warehouse.Relational.ConsumerCombination as cc with (nolock)
	on p.BrandID = cc.BrandID
Where p.PartnerID = '+Cast(@PartnerID as varchar)+'

Create Index IDX_CCIDs_ConsumerCombinationIDs on #CCIDs (ConsumerCombinationID) 
'
End

If @ForcastType = 1 and @Brands is null
Begin
Set @CC_IDs = '
------------------------------------------------------------------------------------
-----------------------------Get ConsumerCombinationIDs-----------------------------
------------------------------------------------------------------------------------

Select	ConsumerCombinationID,
		a.BrandID,
		[Type]
Into #CCIDs
from 
(Select BrandID,
		''Partner'' as [Type]
from Warehouse.Relational.Partner as p with (nolock)
Where p.PartnerID = '+Cast(@PartnerID as varchar)+'
Union All 
Select CompetitorID as BrandID,
		''Competitor'' as [Type]
from Warehouse.Relational.Partner as p with (nolock)
inner join Warehouse.Relational.BrandCompetitor as bc with (nolock)
	on p.BrandID = bc.BrandID
Where p.PartnerID = '+Cast(@PartnerID as varchar)+'
) as a
inner join Warehouse.Relational.ConsumerCombination as cc with (nolock)
	on a.BrandID = cc.BrandID

Create Index IDX_CCIDs_ConsumerCombinationIDs on #CCIDs (ConsumerCombinationID) 
'
End

If @ForcastType = 1 and @Brands is not null
Begin
Set @CC_IDs = '
------------------------------------------------------------------------------------
-----------------------------Get ConsumerCombinationIDs-----------------------------
------------------------------------------------------------------------------------

Select	ConsumerCombinationID,
		a.BrandID,
		[Type]
Into #CCIDs
from 
(Select BrandID,
		''Partner'' as [Type]
from Warehouse.Relational.Partner as p with (nolock)
Where PartnerID = '+Cast(@PartnerID as varchar)+'
Union All 
Select	BrandID,
		''Competitor'' as [Type]
From Warehouse.Relational.Brand as b with (nolock)
Where BrandID in ('+@Brands+')
) as a
inner join Warehouse.Relational.ConsumerCombination as cc with (nolock)
	on a.BrandID = cc.BrandID

Create Index IDX_CCIDs_ConsumerCombinationIDs on #CCIDs (ConsumerCombinationID) 
'
End

Declare @Trans as nvarchar(max),@Groups as nvarchar(max),@Lapse1 nvarchar(max),@Lapse2 nvarchar(max)

Set @Trans = '
------------------------------------------------------------------------------------
--------------------------------Get List of Brands----------------------------------
------------------------------------------------------------------------------------
Select	c.[Type],
		c.BrandID,
		b.BrandName,
		Count(*) as CCIDs_Count
from #CCIDs as C
inner join Warehouse.Relational.Brand as b
	on c.BrandID = b.BrandID
Group By c.[Type],
		c.BrandID,
		b.BrandName
------------------------------------------------------------------------------------
-----------------------------Get TransactionalSpend---------------------------------
------------------------------------------------------------------------------------

Select	c.CinID,
		Max(TranDate) as Sector_LastTransaction,
		Max(Case
				When [Type] = ''Partner'' then TranDate
				Else NULL
			End) as Partner_LastTransaction 	
Into #Trans
From #Customers as c
inner join Warehouse.Relational.ConsumerTransaction as ct
	on c.CINID = ct.CINID
inner join #CCIDs as cc
	on ct.ConsumerCombinationID = cc.ConsumerCombinationID
Where TranDate Between '''+ @Trans_StartDate + ''' and ''' + @Trans_EndDate + '''
Group By c.CinID'

If @Lapse1Date is not null and @Lapse1Name is not null
Begin
Set @Lapse1 ='
			When Partner_LastTransaction <= '''+@Lapse1Date+''' then '''+@Lapse1name+''''
End
If @Lapse2Date is not null and @Lapse2Name is not null
Begin
Set @Lapse2 = '
			When Partner_LastTransaction <= '''+@Lapse2Date+''' then '''+@Lapse2name+''''
End


Set @Groups = '
------------------------------------------------------------------------------------
-----------------------------Categorise Customers-----------------------------------
------------------------------------------------------------------------------------

Select  CinID,
		Case
			When Partner_LastTransaction is null then ''Aquire'''+coalesce(@Lapse1,'')+Coalesce(@Lapse2,'')
+'
			Else ''Current''
		End as [Category],
		Sector_LastTransaction,
		Partner_LastTransaction
Into #Customer_Category
From #Trans

------------------------------------------------------------------------------------
-----------------------------Category Customer Counts-------------------------------
------------------------------------------------------------------------------------

Select	Category,
		Count(*)
From	#Customer_Category
Group By Category
'

Select @Part1+
@CC_IDs+@Trans+@Groups
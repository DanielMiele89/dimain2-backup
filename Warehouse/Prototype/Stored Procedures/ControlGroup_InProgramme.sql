CREATE Procedure Prototype.ControlGroup_InProgramme (@PartnerID int,
													@AcquireCtrl int,
													@LapsedCtrl int,
													@ShopperCtrl int
												   )
--With Execute as Owner
As 


Declare @PID int = @PartnerID,
		@LapCtrl real = Cast(@LapsedCtrl as real)/100,
		@ShopCtrl real = Cast(@ShopperCtrl as real)/100,
		@AcqCtrl real = Cast(@AcquireCtrl as real)/100,
		@Today datetime,
		@time DATETIME,
		@msg VARCHAR(2048)

SELECT @msg = 'Create Partner Table - Start'
EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

if object_id('Tempdb..#Partner') is not null drop table #Partner
Select p.PartnerID,p.BrandID,Acquire,Lapsed
Into #Partner
From Staging.Partners_IncFuture as p
inner join Segmentation.ROC_Shopper_Segment_Partner_Settings as b
	on p.PartnerID = b.PartnerID
Where p.PartnerID = @PID

SELECT @msg = 'Create Partner Table - End'
EXEC Staging.oo_TimerMessage @msg, @time OUTPUT


SELECT @msg = 'Create Brand Table - Start'
EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

if object_id('Tempdb..#Brands') is not null drop table #Brands
Select BrandID 
Into #Brands
From #Partner

SELECT @msg = 'Create Brand Table - End'
EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

SELECT @msg = 'Create In Programme Table - Start'
EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

Declare @TableName varchar(150) = 'Sandbox.'+system_user+'.InprogrammeControl'+Cast(@PartnerID as Varchar(5))+'_'+Replace(Convert(varchar,getdate(),111),'/',''),
		@qry nvarchar(max)

Set @Qry = '
if object_id('''+@TableName+''') is not null drop table '+@TableName+'

CREATE TABLE '+@TableName+'(
	[FanID] [int] NOT NULL,
	[cinid] [int] NOT NULL,
	[Gender] [char](1) NULL,
	[AgeCategory] [varchar](12) NULL,
	[CameoCode] [varchar](151) NOT NULL,
	[Region] [varchar](30) NULL,
	[MarketableByEmail] [bit] NULL,
	[HMcomboID] [int] NULL,
	[HMscore] [int] NULL,
	[SpendCat] [varchar](50) NULL,
	[Sales] [int] NULL,
	[Txs] [int] NULL,
	[Selection] [varchar](20) NULL,
	Primary Key (CINID)
) 

CREATE NonCLUSTERED INDEX [Cix_InprogrammeControl'+Cast(@PartnerID as Varchar(5))+'_'+Replace(Convert(varchar,getdate(),111),'/','')+'_SpendCat] 
			ON '+'Sandbox.'+system_user+'.InprogrammeControl'+Cast(@PartnerID as Varchar(5))+'_'+Replace(Convert(varchar,getdate(),111),'/','')+'(SpendCat) 
					INCLUDE ([cinid])'


--Select @Qry

Exec SP_ExecuteSQl @Qry

SELECT @msg = 'Create In Programme Table - End'
EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

----------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------

SELECT @msg = 'Populate Customers - Start'
EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

Set @Qry = ''
Set @Qry = '
Insert INTO '+@TableName+'(FanID,
						   CinID,
						   Gender,
							AgeCategory,
							CameoCode,
							Region,
							MarketableByEmail
							)
SELECT      
            c.FanID
            ,cl.cinid
            ,c.Gender
            ,CASE  
                  WHEN c.AgeCurrent < 18 OR c.AgeCurrent IS NULL THEN ''99. Unknown''
                  WHEN c.AgeCurrent BETWEEN 18 AND 24 THEN ''01. 18 to 24''
                  WHEN c.AgeCurrent BETWEEN 25 AND 29 THEN ''02. 25 to 29''
                  WHEN c.AgeCurrent BETWEEN 30 AND 39 THEN ''03. 30 to 39''
                  WHEN c.AgeCurrent BETWEEN 40 AND 49 THEN ''04. 40 to 49''
                  WHEN c.AgeCurrent BETWEEN 50 AND 59 THEN ''05. 50 to 59''
                  WHEN c.AgeCurrent BETWEEN 60 AND 64 THEN ''06. 60 to 64''
                  WHEN c.AgeCurrent >= 65 THEN ''07. 65+'' 
			END as AgeCategory
            ,ISNULL((cam.[CAMEO_CODE_GROUP] +''-''+ camg.CAMEO_CODE_GROUP_Category),''99. Unknown'') as CameoCode
			,c.Region
			,c.MarketableByEmail
FROM Warehouse.Relational.Customer c  WITH (NOLOCK)
LEFT OUTER JOIN Warehouse.Relational.CAMEO cam  WITH (NOLOCK)
    ON c.PostCode = cam.Postcode
LEFT OUTER JOIN Warehouse.Relational.CAMEO_CODE_GROUP camg  WITH (NOLOCK)
    ON cam.CAMEO_CODE_GROUP = camg.CAMEO_CODE_GROUP
INNER JOIN warehouse.relational.CINList as cl 
	ON c.SourceUID=cl.CIN
WHERE 
c.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
AND c.CurrentlyActive = 1
'
--Select @Qry
Exec SP_ExecuteSQL @Qry

SELECT @msg = 'Populate Customers - End'
EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

----------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------

SELECT @msg = 'Populate Heatmap Values - Start'
EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

Set @qry = '
update a 
set a.HMcomboID = lk2.comboID
from '+@TableName+' as a
left join Warehouse.InsightArchive.HM_Combo_SalesSTO_Tool lk2 on a.gender=lk2.gender and a.CameoCode=lk2.CAMEO_grp and a.AgeCategory=lk2.Age_Group

--SELECT @msg = ''Populate Heatmap ComboID - End''
--EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

-- Get Heatmap itself
IF OBJECT_ID(''tempdb..#HeatmapCombo'') IS NOT NULL DROP TABLE #HeatmapCombo
select *
into #HeatmapCombo
from  Warehouse.InsightArchive.SalesSTO_HeatmapBrandCombo_Index 
where brandid in (select BrandID from #brands)

Create nonclustered index cix_HeatmapCombo_ComboID_2 on #HeatmapCombo (ComboID_2)

update a
set a.HMscore = hm.Index_RR
from '+@TableName+' a
left join #HeatmapCombo hm 
	on a.HMcomboID=hm.ComboID_2
'

Exec sp_ExecuteSQL @Qry

SELECT @msg = 'Populate Heatmap Values - End'
EXEC Staging.oo_TimerMessage @msg, @time OUTPUT
------------Create List of CC_IDs for Brand
SELECT @msg = 'Populate Transactional and Ctrl Group Values - Start'
EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

Set @Qry = '
if object_id(''tempdb..#ccids1'') is not null drop table #ccids1
select ConsumercombinationID
into #ccids1
from Relational.ConsumerCombination cc
where
cc.brandID = (select BrandID from #brands)

create clustered index INX on #ccids1(ConsumercombinationID)

---------- Set Dates
		declare @extractS date , @extractA date , @extractL date , @ALeng int , @LLeng int 
		set @extractS = getdate()
		set @ALeng = '+(Select Cast(Acquire as varchar(4)) as ALen from #Partner)+'
		set @LLeng = '+(Select Cast(Lapsed as varchar(4)) as ALen from #Partner)+'
		set @extractA = dateadd(month,-@ALeng,@extractS)
		set @extractL = dateadd(month,-@LLeng,@extractS) 

---------- II, Get sales
			if object_id(''tempdb..#Sales'') is not null drop table #Sales
			select ct.CINID
					,max(case when trandate between @extractL and @extractS then 1 else NULL end) as SpderL
					,1 as Spder
					,sum(amount) as sales 
					,count(1) as Txs 
			into #Sales
			from #ccids1 b
			INNER JOIN Warehouse.Relational.ConsumerTransaction ct on b.ConsumerCombinationID=ct.ConsumerCombinationID
			INNER JOIN '+@TableName+' c on c.cinid = ct.cinid
			where TranDate between @extractA and @extractS
			--AND ISRefund = 0
			group by ct.cinid


			update a
			set a.SpendCat =		case 
										when b.CINID is NULL then ''Acquire''
										when b.SpderL is NULL then ''Lapsed''
										when b.spder = 1 then ''Shopper''
									end,

				a.Sales =			case 
										when b.Sales is null then 0 
										else b.Sales 
									end,

				a.Txs =				case 
										when b.Txs is null then 0 
										else b.Txs 
									end
			from '+@TableName+' a
			left join #Sales b on b.CINID = a.CINID

			-------------------------Create Control Group

			IF OBJECT_ID(''tempdb..#Counts'') IS NOT NULL DROP TABLE #Counts
			create table #Counts(SpendCat varchar(20), Customers int)
	

			insert into #Counts(SpendCat, Customers)
			select	SpendCat, 
					count(*) as Customers
			from '+@TableName+'
			group by SpendCat
			



			-- Acquire
			UPDATE t 
			SET t.Selection = ''Control''
			from '+@TableName+' t
			WHERE CINID in (SELECT TOP (select convert(int, '+Cast(@AcqCtrl as Varchar(7)) +'*(select Customers from #Counts where SpendCat = ''Acquire''))) CINID
										FROM '+@TableName+'
										where SpendCat = ''Acquire''
										ORDER BY Newid())

			-- Shopper
			UPDATE t 
			SET t.Selection = ''Control''
			from '+@TableName+' t
			WHERE CINID in (SELECT TOP (select convert(int, '+Cast(@ShopCtrl as Varchar(7)) +'*(select Customers from #Counts where SpendCat = ''Shopper'')))  CINID
										FROM '+@TableName+'
										where SpendCat = ''Shopper''
										ORDER BY Newid())

			-- Lapsed
			UPDATE t 
						SET t.Selection = ''Control''
						from '+@TableName+' t
						WHERE CINID in (SELECT TOP (select convert(int, '+Cast(@lapCtrl as Varchar(7)) +'*(select Customers from #Counts where SpendCat = ''Lapsed'')))  CINID
										FROM '+@TableName+'
										where SpendCat = ''Lapsed''
										ORDER BY Newid()) 


Select SpendCat,
		Selection,
		Count(*) as Customers,
		Case
			When Count(*) < 5000 then ''TOO SMALL''
			Else ''OK''
		End as CtrlGrp
From '+@TableName+'
Group by SpendCat,Selection'

--Select @Qry

Exec SP_ExecuteSQL @Qry

SELECT @msg = 'Populate Transactional and Ctrl Group Values - End'
EXEC Staging.oo_TimerMessage @msg, @time OUTPUT
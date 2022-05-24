-- =============================================
-- Author:		<Shaun Hide>
-- Create date: <10/04/2017>
-- Description:	<Cumulative Gains for ROC>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_CumulGainsROC_v1]
AS
BEGIN
	SET NOCOUNT ON;
	-------------------------------------------------------------------------------------

	Declare @time DATETIME
	Declare @msg VARCHAR(2048)

	SELECT @msg = 'Start'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	-----------------------------------
	-- Read in Dates

	DECLARE		@startfutureperiod date
	Set			@startfutureperiod = (select StartEightWeek from Warehouse.ExcelQuery.ROCEFT_DatesCumulativeGains)

	Declare		@endfutureperiod date
	Set			@endfutureperiod = (select EndEightWeek from Warehouse.ExcelQuery.ROCEFT_DatesCumulativeGains)

	Declare		@endhistoricperiod date
	Set			@endhistoricperiod = (select DATEADD(day,-1,@startfutureperiod))

	Declare		@rundate date
	Set			@rundate = (select RunDate from Warehouse.ExcelQuery.ROCEFT_DatesCumulativeGains)


	-----------------------------------
	-- Publisher Table

	IF OBJECT_ID('tempdb..#Publisher') IS NOT NULL DROP TABLE #Publisher
	SELECT	PublisherID
			,PublisherName
			,Algorithm
			,ROW_NUMBER() OVER (ORDER BY PublisherName) AS PubNo
	INTO	#Publisher
	FROM	Warehouse.ExcelQuery.ROCEFT_Publishers

	-- R4G Fudge
	DECLARE @PublisherNo INT = (SELECT MAX(PubNo) FROM #Publisher) + 1
	INSERT INTO #Publisher
		VALUES (NULL,'R4G','Random',@PublisherNo)

	--SELECT * FROM #Publisher

	-----------------------------------
	-- Publisher Loop
	DECLARE @PublisherID Int
	DECLARE @PubNo		 Int
	Set @PubNo = 1

	WHILE @PubNo <= (select max(PubNo) from #Publisher)
		BEGIN
			DECLARE @PubID int, @Publisher varchar(50), @Algo_Applied varchar(50)
			SET @PubID =		(select PublisherID from #Publisher where PubNo = @PubNo)
			SET @Publisher =	(select PublisherName from #Publisher where PubNo = @PubNo)
			SET @Algo_Applied = (select Algorithm from #Publisher where PubNo = @PubNo)
		
			DECLARE @BrandID int
			DECLARE @rowno int
			Set @rowno=1

			If @Algo_Applied = 'Random' 
				BEGIN
					SELECT @msg = 'Starting random assignment for ' + @Publisher
					EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

					WHILE @rowno  <= (select max(rowno) from Warehouse.ExcelQuery.ROCEFT_RefreshBrand)  
						BEGIN
							SET @BrandID = (select BrandID from Warehouse.ExcelQuery.ROCEFT_RefreshBrand where rowno = @rowno)

							---------------------------------------------------------------------------------------------
							-- Random ROC Profiling Added
							Insert Into Warehouse.ExcelQuery.ROCEFT_ROCCumulativeGains
								Select		@Publisher as Publisher
											,@BrandID as BrandID
											,Shopper_Segment
											,Decile
											,0.1 as ProportionOfCardholders
											,0.1 as ProportionOfSpenders
											,0.1 as ProportionOfSpend
											,0.1 as ProportionOfTrans
								From		Warehouse.ExcelQuery.ROCEFT_RBSCumulativeGains
								Group By	Shopper_Segment
											,Decile
								Order by	Publisher
											,Shopper_Segment
											,Decile

							SET @rowno = @rowno + 1
						END

					SELECT @msg = 'Random assignment for ' + @Publisher + ' complete'
					EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT
				END
			If @Algo_Applied = 'Ranked'
				BEGIN

					SELECT @msg = 'Starting assignment for ' + @Publisher
					EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

					---------------------------------------------------------------------------------------------
					-- Generate a generic ranked acquire for the publisher
					---------------------------------------------------------------------------------------------

					---------------------------------------------------------------------------------------------
					-- Brand Table
					If Object_ID('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
					Select		distinct 
								br.BrandID
								,br.BrandName
								,p.PartnerID
					Into		#Brand
					From		Warehouse.Relational.Brand br
					Left Join	Warehouse.Staging.Partners_Vs_Brands p on br.BrandID = p.BrandID
					Left Join	Warehouse.Relational.Partner part on br.BrandID = part.BrandID
					Where		br.BrandID in (12,23,75,116,142,188,190)

					-- select * from #Brand

					-------------------------------------------------------------------------------------
					-- Determine the acquire, and lapsed length for each brand

					If Object_ID('tempdb..#MasterRetailerFile') IS NOT NULL DROP TABLE #MasterRetailerFile
					Select	br.*
							,mrf.[SS_AcquireLength]
							,mrf.[SS_LapsersDefinition]
							,mrf.[SS_WelcomeEmail]
							,cast(SS_Acq_Split*100 as int) as Acquire_Pct
					Into	#MasterRetailerFile 
					From	Warehouse.Relational.MRF_ShopperSegmentDetails mrf
					Join	Warehouse.Relational.Partner p 
						 on	mrf.PartnerID = p.PartnerID
					Join	#Brand br
						 on p.BrandID = br.BrandID

					-- select * from #MasterRetailerFile

					If Object_ID('tempdb..#Settings') IS NOT NULL DROP TABLE #Settings
					Select distinct		a.BrandName
										,a.BrandID
										,a.PartnerID
										,a.sectorID
										,coalesce(mrf.SS_AcquireLength,blk.acquireL,a.AcquireL0) as AcquireL
										,coalesce(mrf.SS_LapsersDefinition,blk.LapserL,a.LapserL0) as LapserL
					Into				#Settings
					From	(
								Select		b.BrandID
											,b.BrandName
											,br.PartnerID
											,b.sectorID
											,case when b.BrandName in ('Tesco', 'Asda','Sainsburys','Morrisons') then 3 else lk.acquireL end as AcquireL0
											,case when b.BrandName in ('Tesco', 'Asda','Sainsburys','Morrisons') then 1 else lk.LapserL end as LapserL0
											,lk.Acquire_Pct as Acquire_Pct0
								From		Warehouse.Relational.Brand b
								Join		#Brand br
										on  b.BrandID = br.BrandID
								Left Join	Warehouse.Prototype.ROCP2_SegFore_SectorTimeFrame_LK lk 
										on	lk.sectorid=b.sectorID
							) a
					Left Join			Warehouse.Prototype.ROCP2_SegFore_BrandTimeFrame_LK blk 
									on	blk.brandid=a.brandID
					Left Join			#MasterRetailerFile mrf 
									on	mrf.BrandID = a.BrandID
					Where			coalesce(mrf.SS_AcquireLength,blk.acquireL,AcquireL0) is not null

					-- select * from #Settings

					-------------------------------------------------------------------------------------
					-- Determine the start and end dates for each brand (based off acquire lengths)

					If Object_ID('tempdb..#Settings_w_Dates') IS NOT NULL DROP TABLE #Settings_w_Dates
					Select		a.*
								,DATEADD(MONTH,-AcquireL,@startfutureperiod) as HistStart
								,cast(@endhistoricperiod as Date) as HistEnd
								,DATEADD(Month,-LapserL,@startfutureperiod) as LapseStart
								,cast(@startfutureperiod as Date) as FutureStart
								,cast(@endfutureperiod as Date) as FutureEnd
					Into		#Settings_w_Dates
					From		#Settings a

					-- select * from #Settings_w_Dates

					-------------------------------------------------------------------------------------
					-- Collect the required compositeIDs

					If Object_ID('tempdb..#Base') IS NOT NULL DROP TABLE #Base
					Select distinct f.compositeID
					Into			#Base
					From			SLC_Report.dbo.fan f
					Join			SLC_Report.dbo.pan p
								on	f.compositeID = p.compositeID	
					Where			f.ClubID = @PubID
								and additiondate <= @endfutureperiod
								and (removaldate is null or removaldate >= (DATEADD(dd, 1, @endfutureperiod))) 

					CREATE CLUSTERED INDEX ix_compID on #Base(compositeID)

					-------------------------------------------------------------------------------------
					-- Historic Spend by Partner and CompositeID

					If Object_ID('tempdb..#HistoricData_1') IS NOT NULL DROP TABLE #HistoricData_1
					Select          br.BrandID
									,base.CompositeID
									,sum(m.Amount) as Spend
									,COUNT(1) as Frequency
									,max(m.TransactionDate) as LastDate
					Into			#HistoricData_1
					From			SLC_Report.dbo.Pan p
					inner join		SLC_Report.dbo.Match  m on P.ID = m.PanID   --- to get the MATCH ID relating to the PAN (Card)
					inner join		SLC_Report.dbo.fan f on p.CompositeID = f.CompositeID
					inner join		SLC_Report.dbo.RetailOutlet ro on m.RetailOutletID = ro.ID
					inner join		SLC_Report.dbo.Partner part on ro.PartnerID = part.ID
					inner join		SLC_Report.dbo.Trans t on t.MatchID = m.ID
					inner join		SLC_Report.dbo.TransactionType tt on tt.ID = t.TypeID
					inner join		#Base base on base.CompositeID = f.CompositeID
					inner join		#Settings_w_Dates br 
								on	br.PartnerID = part.ID
								and	br.HistStart <= m.TransactionDate 
								and m.TransactionDate <= br.HistEnd 
					where			f.ClubID = @PubID   
									and m.status in (1)-- Valid transaction status
									and m.rewardstatus in (0,1)-- Valid customer status
					group by		br.BrandID
									,base.CompositeID

					CREATE CLUSTERED INDEX ix_CompID on #HistoricData_1(CompositeID)

					-------------------------------------------------------------------------------------
					-- Cross Join PartnerID and CompositeID

					If Object_ID('tempdb..#CrossJoin') IS NOT NULL DROP TABLE #CrossJoin
					Select	b.*
					Into #CrossJoin
					From (	
							Select *
							From #Base
							cross join 
							(Select distinct BrandID 
							From #HistoricData_1) a
						 )  b

					CREATE INDEX ix_ID on #CrossJoin(BrandID)
					CREATE INDEX ix_CompID on #CrossJoin(CompositeID)

					-------------------------------------------------------------------------------------
					-- Assign Segments

					If Object_ID('tempdb..#HistoricData_2') IS NOT NULL DROP TABLE #HistoricData_2
					Select			 x.BrandID
									,x.CompositeID
									,isnull(a.Frequency,0) as Frequency
									,a.LastDate
									,isnull(a.Spend,0) as Spend
									,case 
										when b.LapseStart <= a.LastDate then 'Shopper'
										when a.LastDate < b.LapseStart then 'Lapsed'
										else 'Acquire'
									 end as Shopper_Segment
					Into			#HistoricData_2
					From			#CrossJoin x
					Left outer join	#HistoricData_1 a 
								on	x.CompositeID = a.CompositeID
								and	x.BrandID = a.BrandID
					Left Join	(Select distinct 
										BrandID
										,HistStart
										,HistEnd
										,LapseStart
										,FutureStart
										,FutureEnd										
								From #Settings_w_Dates
								) b
								on	x.BrandID = b.BrandID

					CREATE INDEX ix_ID on #HistoricData_2(BrandID)
					CREATE INDEX ix_CompID on #HistoricData_2(CompositeID)

					-- select top 10 * from #HistoricData_2 where spend <> 0

					-------------------------------------------------------------------------------------
					-- Find last trandate for every cardholders 

					Declare @MinHistoricPeriod Date
					Set @MinHistoricPeriod = (Select min(HistStart) From #Settings_w_Dates)

					If Object_ID('tempdb..#HistoricData_3') IS NOT NULL DROP TABLE #HistoricData_3
					Select          base.CompositeID
									,max(m.TransactionDate) as LastDate
					Into			#HistoricData_3
					From			SLC_Report.dbo.Pan p
					inner join		SLC_Report.dbo.Match  m on P.ID = m.PanID   --- to get the MATCH ID relating to the PAN (Card)
					inner join		SLC_Report.dbo.fan f on p.CompositeID = f.CompositeID
					inner join		SLC_Report.dbo.RetailOutlet ro on m.RetailOutletID = ro.ID
					inner join		SLC_Report.dbo.Partner part on ro.PartnerID = part.ID
					inner join		SLC_Report.dbo.Trans t on t.MatchID = m.ID
					inner join		SLC_Report.dbo.TransactionType tt on tt.ID = t.TypeID
					inner join		#Base base on base.CompositeID = f.CompositeID
					where			f.ClubID = @PubID    
									and m.status in (1)-- Valid transaction status
									and m.rewardstatus in (0,1)-- Valid customer status
									and cast(m.transactiondate as date) between @MinHistoricPeriod and @endhistoricperiod 
					group by		base.CompositeID

					CREATE CLUSTERED INDEX ix_CompID on #HistoricData_3(CompositeID)

					-------------------------------------------------------------------------------------
					-- Future Spend by Partner and CompositeID

					if object_id('tempdb..#FutureSpend') is not null drop table #FutureSpend
					Select          br.BrandID
									,base.CompositeID
									,sum(m.Amount)	as Future_Spend
									,COUNT(1)		as Future_Frequency
									,1				as Future_Spender
					Into			#FutureSpend
					From			SLC_Report.dbo.Pan p
					inner join		SLC_Report.dbo.Match  m on P.ID = m.PanID   --- to get the MATCH ID relating to the PAN (Card)
					inner join		SLC_Report.dbo.fan f on p.CompositeID = f.CompositeID
					inner join		SLC_Report.dbo.RetailOutlet ro on m.RetailOutletID = ro.ID
					inner join		SLC_Report.dbo.Partner part on ro.PartnerID = part.ID
					inner join		SLC_Report.dbo.Trans t on t.MatchID = m.ID
					inner join		SLC_Report.dbo.TransactionType tt on tt.ID = t.TypeID
					inner join		#Base base on base.CompositeID = f.CompositeID
					inner join		#Settings_w_Dates br 
								on	br.PartnerID = part.ID
								and	br.FutureStart <= m.TransactionDate 
								and m.TransactionDate <= br.FutureEnd
					where			f.ClubID = @PubID    
									and m.status in (1)-- Valid transaction status
									and m.rewardstatus in (0,1)-- Valid customer status
					group by		br.BrandID
									,base.CompositeID

					CREATE CLUSTERED INDEX ix_CompID on #FutureSpend(CompositeID)

					-------------------------------------------------------------------------------------
					-- Pull a final table together for Ranking

					If Object_ID('tempdb..#Combination_2') IS NOT NULL DROP TABLE #Combination_2
					Select			a.BrandID 
									,a.CompositeID
									,a.Shopper_Segment
									,a.Frequency
									,a.Spend
									,isnull(b.future_Frequency,0) as future_frequency
									,isnull(b.future_Spend,0) as future_spend
									,isnull(b.future_spender,0) as future_spender
									,c.LastDate
									,d.CardAdditionDate
					Into			#Combination_2
					From			#HistoricData_2 a
					Left Join		#FutureSpend b 
								on  a.CompositeID = b.CompositeID
								and a.BrandID = b.BrandID
					Left Join		#HistoricData_3 c on a.CompositeID = c.CompositeID
					Left Join		(	
										Select	a.CompositeID
												,case 
													when max(a.additiondate) is null then '1900-01-01' 
													when max(a.additiondate) is not null and max(a.removaldate) is not null then '1900-01-01'
													else max(a.additiondate) 
												end as CardAdditionDate
										From (
												Select distinct f.compositeID
																,f.ClubID
																,p.AdditionDate
																,p.RemovalDate
												From			SLC_Report.dbo.fan f
												Join			SLC_Report.dbo.pan p
															on	f.compositeID = p.compositeID	
												Where			additiondate <= @endfutureperiod
															and (removaldate is null or removaldate >= (DATEADD(dd, 1, @endfutureperiod)))
											) a
										Group By a.CompositeID
									) d on a.CompositeID = d.CompositeID
					Where		a.Shopper_Segment = 'Acquire' -- Currently this is all we are using

					-------------------------------------------------------------------------------------
					-- Ranking and Deciling

					if object_id('tempdb..#Ranking_1') is not null drop table #Ranking_1
					select		a.*
								,case when Shopper_Segment = 'Acquire' then
									case when LastDate is null then
										ROW_NUMBER() over(partition by BrandID, Shopper_Segment order by CardAdditionDate desc)
									else
										ROW_NUMBER() over(partition by BrandID, Shopper_Segment order by LastDate desc)
									end
								 else 	
									ROW_NUMBER() over(partition by BrandID, Shopper_Segment order by spend desc)
								 end as Ranking_Within_Segment
					into		#Ranking_1
					from		#Combination_2 a

					SELECT @msg = 'Ranking Complete'
					EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

					if object_id('tempdb..#Ranking_2') is not null drop table #Ranking_2
					select		a.*
								,ntile(10) over(partition by BrandID, Shopper_Segment order by Ranking_Within_Segment asc) as Deciles
					into		#Ranking_2
					from		#Ranking_1 a

					SELECT @msg = 'Deciling complete'
					EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

					-------------------------------------------------------------------------------------
					-- Producing Output Table

					If Object_ID('tempdb..#ShopperSegmentMetrics') IS NOT NULL DROP TABLE #ShopperSegmentMetrics
					Select	BrandID
							,Shopper_Segment
							,count(distinct CompositeID)	as TotalShoppers
							,count(distinct (case when Spend > 0 then CompositeID end)) as TotalHisSpenders
							,sum(Spend)		as TotalHisSpend
							,sum(Frequency)	as TotalHisTrans
							,sum(Future_Spender)    as TotalFutSpenders
							,sum(Future_Spend)		as TotalFutSpend
							,sum(Future_Frequency)	as TotalFutTrans
					Into	#ShopperSegmentMetrics
					From	#Ranking_2
					Group by BrandID
							,Shopper_Segment
				
					-- select * from #ShopperSegmentMetrics

					If Object_ID('tempdb..#Output') IS NOT NULL DROP TABLE #Output
					Select	a.BrandID
							,a.Shopper_Segment
							,a.Deciles
							,(1.0*Cardholder_Count)/TotalShoppers	as ProportionOfCardholders
							,(1.0*Spender_Count)/TotalFutSpenders	as ProportionOfSpenders
							,(1.0*Spend_Count)/TotalFutSpend		as ProportionOfSpend
							,(1.0*Frequency_Count)/TotalFutTrans	as ProportionOfTrans
					Into	#Output
					From	(
								Select	BrandID
										,Shopper_Segment
										,Deciles
										,count(distinct CompositeID)	as Cardholder_Count	
										,sum(Future_Spender)			as Spender_Count
										,sum(Future_Spend)				as Spend_Count
										,sum(Future_Frequency)			as Frequency_Count
								From	#Ranking_2
								Group By BrandID
										,Shopper_Segment
										,Deciles
							) a
					Join	#ShopperSegmentMetrics b
					on		a.BrandID = b.BrandID 
						and a.Shopper_Segment = b.Shopper_Segment
					Order By a.BrandID
							,a.Shopper_Segment
							,a.Deciles
				
					-- select * from #Output order by 1,2,3

					If Object_ID('tempdb..#AcquireMetrics') IS NOT NULL DROP TABLE #AcquireMetrics
					Select  @Publisher as Publisher
							,Shopper_Segment
							,Deciles
							,AVG(ProportionOfCardholders) as ProportionOfCardholders
							,AVG(ProportionOfSpenders) as ProportionOfSpenders
							,AVG(ProportionOfSpend) as ProportionOfSpend
							,AVG(ProportionOfTrans) as ProportionOfTrans
					Into	#AcquireMetrics
					From	#Output
					Group By Shopper_Segment
							,Deciles
					Order By Publisher
							,Shopper_Segment
							,Deciles
				
					-- select * from #AcquireMetrics

					-------------------------------------------------------------------------------------
					-- Looping through the brands

					WHILE @rowno  <= (select max(rowno) from Warehouse.ExcelQuery.ROCEFT_RefreshBrand)  
						BEGIN
							SET @BrandID = (select BrandID from Warehouse.ExcelQuery.ROCEFT_RefreshBrand where rowno = @rowno)

							---------------------------------------------------------------------------------------------
							-- Ranked ROC Profiling Added - Lapsed and Shopper
							Insert Into Warehouse.ExcelQuery.ROCEFT_ROCCumulativeGains
								Select		@Publisher as Publisher
											,@BrandID as BrandID
											,Shopper_Segment
											,Decile
											,cast(round(sum(ProportionOfCardholders),11) as decimal(12,11)) as ProportionOfCardholders
											,cast(round(sum(ProportionOfSpenders),11) as decimal(12,11)) as ProportionOfSpenders
											,cast(round(sum(ProportionOfSpend),11) as decimal(12,11)) as ProportionOfSpend
											,cast(round(sum(ProportionOfTrans),11) as decimal(12,11)) as ProportionOfTrans
								From	(
											Select	*
											From	Warehouse.ExcelQuery.ROCEFT_RBSCumulativeGains
											Where	BrandID = @BrandID
										) a
								Where		Shopper_Segment in ('Lapsed','Shopper')
								Group By	Shopper_Segment
											,Decile
								Order by	Publisher
											,Shopper_Segment
											,Decile

							---------------------------------------------------------------------------------------------
							-- Ranked ROC Profiling Added - Acquire					
							Insert Into Warehouse.ExcelQuery.ROCEFT_ROCCumulativeGains
								Select		Publisher
											,@BrandID as BrandID
											,Shopper_Segment
											,Deciles
											,ProportionOfCardholders
											,ProportionOfSpenders
											,ProportionOfSpend
											,ProportionOfTrans
								From		#AcquireMetrics

							SET @rowno = @rowno + 1
						END

					SELECT @msg = 'Random assignment for ' + @Publisher + ' complete'
					EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

				END

			Set @PubNo = @PubNo + 1
		END
END
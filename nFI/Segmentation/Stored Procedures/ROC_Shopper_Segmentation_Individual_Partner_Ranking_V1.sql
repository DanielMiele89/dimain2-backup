

/********************************************************************************************
** Name: [Segmentation].[ROC_Shopper_Segmentation_Individual_Partner_Ranking_V1] 
** Desc: Ranking per Segment for nFIs 
** Auth: Zoe Taylor
** Date: 14/03/2017
*********************************************************************************************
** Change History
** ---------------------
** #No		Date		Author			Description 
** --		--------	-------			------------------------------------
** 1    
*********************************************************************************************/

CREATE Procedure [Segmentation].[ROC_Shopper_Segmentation_Individual_Partner_Ranking_V1] (@PartnerID int)

as

declare @TableName varchar(50),	@time DATETIME,	@msg VARCHAR(2048)
-- Test PartnerID @PartnerID


/******************************************************************
		
		Rank Spender and Lapsed 

******************************************************************/	
	-------------------------------------------------------------------
	--		Get distinct values and assign ranking
	-------------------------------------------------------------------
	IF Object_id('tempdb..#RankedSpend') IS NOT NULL  DROP TABLE #RankedSpend
	Select *,
			ROW_NUMBER() OVER(PARTITION BY ClubID, Segment ORDER BY Spend DESC) AS RowNum
	Into #RankedSpend
	From (
			Select Distinct ClubID,Spend,Segment
			from Segmentation.Roc_Shopper_Segment_SpendInfo
			Where PartnerID = @PartnerID
			and Segment in (8, 9)
			And Spend is not null
			
		) as a

	Create NonClustered index cix_Ranked_SpendSegment on #RankedSpend (Spend,Segment,ClubID) include (RowNum)

	SELECT @msg = 'Shopper and Lapsed - Assigned each distinct spend value a ranking'
	EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

	-------------------------------------------------------------------
	--		Assigns rank to each customer
	-------------------------------------------------------------------
	IF Object_id('tempdb..#ShopperRanking') IS NOT NULL  DROP TABLE #ShopperRanking
	Select c.FanID, c.ClubID, c.Spend, r.RowNum [Ranking] 
	into #ShopperRanking
	from #RankedSpend r
	inner join Segmentation.Roc_Shopper_Segment_SpendInfo c
		on	c.Spend = r.Spend 
			and c.Segment = r.Segment
			and c.ClubID = r.ClubID
	order by r.ClubID, r.Segment, r.Spend, r.RowNum, c.FanID

	Create NonClustered index cix_CustomerRankingSL_FanIDSpend on #ShopperRanking (FanID, Spend) include (Ranking)

	SELECT @msg = 'Shopper and Lapsed - Customers ranked'
	EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

/******************************************************************
			
		Rank Acquire  

******************************************************************/
	
	IF Object_id('tempdb..#AcquireRanking') IS NOT NULL  DROP TABLE #AcquireRanking
	Create Table #AcquireRanking (
									FanID int,
									PartnerID int,
									ClubID int,
									Ranking INT,
									Primary key (FanID)
								)

	-------------------------------------------------------------------
	--		Get all customers with no spend in acquire
	-------------------------------------------------------------------
	
	IF Object_id('tempdb..#AcquireCustomers') IS NOT NULL  DROP TABLE #AcquireCustomers 	
	Select si.ClubID, si.FanID, si.PartnerID, si.Segment
	Into #AcquireCustomers
	From Segmentation.Roc_Shopper_Segment_SpendInfo si
	Where si.Segment = 7
	and si.PartnerID = @PartnerID

	Create clustered index idx_AcquireCustomers_FanID on #AcquireCustomers (FanID)

	SELECT @msg = 'Acquire - customers details retrieved'
	EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

	-------------------------------------------------------------------
	--		Rank customers with incentivised spend
	-------------------------------------------------------------------
			
			IF Object_id('tempdb..#CustomerTrans') IS NOT NULL  DROP TABLE CustomerTrans 	
			Create Table #CustomerTrans (
										FanID int,
										ClubID int, 
										TransDate date,
										Primary Key (FanID)
										)

			-------------------------------------------------------------------
			--		Get most recent transaction date for customers
			-------------------------------------------------------------------
			Insert into #CustomerTrans
			Select a.Fanid, a.ClubID, max(pt.TransactionDate) as [TransDate]			
			from #AcquireCustomers a
			Left Outer Join Relational.PartnerTrans pt with (nolock)
				on a.Fanid = pt.FanID
			Group by a.clubid, a.FanID
							 
			SELECT @msg = 'Acquire Part 1 - Customers trans retrieved'
			EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

			-------------------------------------------------------------------
			--		Assign ranking to each transaction date
			-------------------------------------------------------------------

			IF Object_id('tempdb..#TransactionRank') IS NOT NULL  DROP TABLE #TransactionRank 	
			Select *, ROW_NUMBER() Over (Partition by ClubID Order by TransDate Desc) as [Ranking]
			Into #TransactionRank
			From (
					Select DISTINCT ClubID, TransDate 
					from #CustomerTrans ct
				) x

			create clustered index idx_TransactionRank_CLubIDTransDate on #TransactionRank (ClubID, TransDate)

			SELECT @msg = 'Acquire Part 1 - Transaction dates ranked'
			EXEC Staging.oo_TimerMessage @msg, @time OUTPUT
	
			-------------------------------------------------------------------
			--		Assign customers the ranking
			-------------------------------------------------------------------	

			Insert into #AcquireRanking
			Select ct.FanID, @PartnerID as PartnerID, ct.ClubID, tr.Ranking
			From #CustomerTrans ct
			Left join #TransactionRank tr 
				on ct.TransDate = tr.Transdate
				and ct.ClubID = tr.clubid
			Where tr.transdate is not null			

			SELECT @msg = 'Acquire Part 1 - Customers ranked on spend'
			EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

	-------------------------------------------------------------------
	--		Rank customers with no spend on card
	-------------------------------------------------------------------
			
			IF Object_id('tempdb..#CustomerCards') IS NOT NULL  DROP TABLE #CustomerCards 			  
			Create Table #CustomerCards (
										FanID int, 
										ClubID int,
										CardAdditionDate date,
										Primary Key (FanID)
										)
										
			-- ********************** Amendment Start (ZT '2017-03-16') ********************** 
			-- ***** Reason for amendment: No longer using registration on scheme date, now using latest card addition date			
			/*
			-------------------------------------------------------------------
			--		Get customer registration date where there is no incentived
			--		spend
			-------------------------------------------------------------------
						
			Insert Into #CustomerRegistration
			Select a.Fanid, a.ClubID, c.RegistrationDate
			from #AcquireCustomers a
			Left Outer Join relational.Customer c
				on c.FanID = a.FanID
				and c.ClubID = a.ClubID
			Left outer join #AcquireRanking ar
				on ar.fanid = a.fanid
			Where ar.FanID is null

			-- *********************** Amendment End  (ZT '2017-03-17') ********************** 
			*/

			-------------------------------------------------------------------
			--		Get customer card details and their latest card addition 
			--		date
			-------------------------------------------------------------------
			
			Insert into #CustomerCards
			Select a.FanID, a.ClubID, case 
									when max(pc.StartDate) is null then '1900-01-01' 
									When max(pc.startdate) is not null and max(pc.enddate) is not null then '1900-01-01'
									else max(pc.StartDate) End as CardAdditionDate
			From #AcquireCustomers a
			Left Outer Join #AcquireRanking ar
				on ar.FanID = a.FanID
			Left Outer Join Relational.Customer_PaymentCard pc
				on pc.FanID = a.FanID
			Where ar.FanID is NULL
			--and pc.enddate is NULL
			Group by a.FanID, a.ClubID

			-------------------------------------------------------------------
			--		Get customers that previously had a card but no longer have 
			--		an active card
			-------------------------------------------------------------------	
					
			--Insert into #CustomerCards
			--Select a.FanID, a.ClubID, '1900-01-01' as CardAdditionDate
			--From (			  
			--	Select a.FanID, a.ClubID
			--	From  #AcquireCustomers a
			--	left join  #CustomerCards c
			--		on a.fanid = c.fanid
			--	left join #AcquireRanking ar
			--		on ar.fanid = a.fanid
			--	where c.fanid is null
			--		and ar.fanid is null
			--) a

			SELECT @msg = 'Acquire Part 2 - Customers registration dates retrieved'
			EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

			-------------------------------------------------------------------
			--		Assign rank to registration dates
			-------------------------------------------------------------------
			
			IF Object_id('tempdb..#RegistrationRank') IS NOT NULL  DROP TABLE #RegistrationRank 	
			Select ClubID, CardAdditionDate, ROW_NUMBER() Over (Partition by ClubID Order by x.CardAdditionDate desc) as [Ranking] 
			Into #RegistrationRank
			From (
					Select distinct ClubID, 
									CardAdditionDate
					From #CustomerCards
			) x

			Create clustered index idx_RegistrationRank_CLubIDAdditionDate on #RegistrationRank (ClubID, CardAdditionDate)
			
			SELECT @msg = 'Acquire Part 2 - Registration dates ranked'
			EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

			-------------------------------------------------------------------
			--		Assign customers the ranking
			-------------------------------------------------------------------
		
			Insert into #AcquireRanking
			Select c.FanID, @PartnerID as PartnerID, c.ClubID, r.Ranking
			from #CustomerCards c
			Left Outer Join #RegistrationRank r
				on r.CardAdditionDate = c.CardAdditionDate
				and c.ClubID = r.clubid
				
			SELECT @msg = 'Acquire Part 2 - Customers ranked'
			EXEC Staging.oo_TimerMessage @msg, @time OUTPUT
	
/******************************************************************F
		
		Update Ranking tables 

******************************************************************/

	-------------------------------------------------------------------
	--		Delete previous ranking
	-------------------------------------------------------------------

	DELETE FROM Segmentation.Roc_Shopper_Segment_CustomerRanking
	where PartnerID = @PartnerID

	SELECT @msg = 'Previous ranking for partner deleted from Segmentation.Roc_Shopper_Segment_CustomerRanking'
	EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

	-------------------------------------------------------------------
	--		Insert Shopper and Lapsed Ranking
	-------------------------------------------------------------------

	INSERT INTO Segmentation.Roc_Shopper_Segment_CustomerRanking
	SELECT FanID, @PartnerID [PartnerID], Ranking [Ranking] 
	FROM #ShopperRanking

	SELECT @msg = 'Shopper and Lapsed - New rankings inserted into Segmentation.Roc_Shopper_Segment_CustomerRanking'
	EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

	-------------------------------------------------------------------
	--		Insert Acquire ranking
	-------------------------------------------------------------------

	INSERT INTO Segmentation.Roc_Shopper_Segment_CustomerRanking
	SELECT FanID, @PartnerID [PartnerID], Ranking [Ranking] 
	FROM #AcquireRanking

	SELECT @msg = 'Acquire - New rankings inserted into Segmentation.Roc_Shopper_Segment_CustomerRanking'
	EXEC Staging.oo_TimerMessage @msg, @time OUTPUT
	


GO
GRANT VIEW DEFINITION
    ON OBJECT::[Segmentation].[ROC_Shopper_Segmentation_Individual_Partner_Ranking_V1] TO [Alan]
    AS [dbo];


GO
GRANT VIEW DEFINITION
    ON OBJECT::[Segmentation].[ROC_Shopper_Segmentation_Individual_Partner_Ranking_V1] TO [Lloyd]
    AS [dbo];


GO
GRANT VIEW DEFINITION
    ON OBJECT::[Segmentation].[ROC_Shopper_Segmentation_Individual_Partner_Ranking_V1] TO [shaun]
    AS [dbo];


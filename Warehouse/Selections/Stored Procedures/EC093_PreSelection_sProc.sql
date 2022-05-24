-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

Create Procedure  Selections.EC093_PreSelection_sProc
AS
BEGIN
	SET ANSI_WARNINGS OFF;
	
		/******************************************************************************************************************************************
														Fetch all customers with 3+ transactions
		******************************************************************************************************************************************/
		
		If object_id('tempdb..#competitors') is not null drop table #competitors
		Select CompetitorID
			 , b.BrandName
		Into #competitors
		From relational.BrandCompetitor bc
		Inner join relational.brand b
			on b.brandid = bc.CompetitorID
		Where bc.BrandID = 1370
		
		If object_id('tempdb..#CCs') is not null drop table #CCs
		Select cc.consumercombinationID
			 , c.BrandName
			 , c.CompetitorID
		Into #CCs
		From Relational.consumercombination cc
		Inner join #competitors c
			on c.CompetitorID = cc.BrandID

		create clustered index INX on #CCs(consumercombinationID)

		declare @Today date = getdate()
		declare @YearAgo date = dateadd(year, -1, @Today)
		
		If object_id('tempdb..#Customers') is not null drop table #Customers
		Select ct.CINID
			 , c.fanid
			 , count(1) as TXs
			 , avg(ct.amount) as Sales
		Into #Customers
		From #CCs cc
		Inner join relational.ConsumerTransaction ct
			on ct.ConsumerCombinationID = cc.ConsumerCombinationID
		Inner join relational.cinlist cl
			on cl.CINID = ct.CINID
		Inner join Relational.customer c 
			on c.sourceuid = cl.cin
		Where ct.TranDate between @YearAgo and @Today
		Group by ct.CINID
				,c.fanid
		
		If object_id('Warehouse.Selections.EC093_PreSelection') is not null drop table Warehouse.Selections.EC093_PreSelection
		Select CINID, fanid
		Into Warehouse.Selections.EC093_PreSelection_SuperUsers
		From #Customers
		Where Txs >= 3		
	
		/******************************************************************************************************************************************
											Move all users into temp table showing their available payment methods
		******************************************************************************************************************************************/
		
		If object_id('tempdb..#CPMA') is not null drop table #CPMA
		Select cpma.FanID
			 , cpma.PaymentMethodsAvailableID
		Into #CPMA
		From Warehouse.relational.Customer as c
		inner join warehouse.relational.CustomerPaymentMethodsAvailable as cpma
			on c.FanID = cpma.FanID
		Where EndDate is null
		And c.CurrentlyActive = 1

		/*

		Select *
		From Warehouse.Relational.PaymentMethodsAvailable

		PaymentMethodsAvailableID	Description
		0							Debit Card
		1							Credit Card
		2							Both
		3							None

		*/

		If object_id('Warehouse.Selections.EC093_PreSelection_Debit') is not null drop table  Warehouse.Selections.EC093_PreSelection_Debit
		Select Distinct su.FanID
		Into Warehouse.Selections.EC093_PreSelection_Debit
		From #CPMA cd
		Inner join Warehouse.Selections.EC093_PreSelection_SuperUsers su
			on cd.FanID = su.FanID
		Where PaymentMethodsAvailableID = 0

		If object_id('Warehouse.Selections.EC093_PreSelection_Credit') is not null drop table  Warehouse.Selections.EC093_PreSelection_Credit
		Select Distinct su.FanID
		Into Warehouse.Selections.EC093_PreSelection_Credit
		From #CPMA cd
		Inner join Warehouse.Selections.EC093_PreSelection_SuperUsers su
			on cd.FanID = su.FanID
		Where PaymentMethodsAvailableID = 1

		If object_id('Warehouse.Selections.EC093_PreSelection_DebitCredit') is not null drop table  Warehouse.Selections.EC093_PreSelection_DebitCredit
		Select Distinct su.FanID
		Into Warehouse.Selections.EC093_PreSelection_DebitCredit
		From #CPMA cd
		Inner join Warehouse.Selections.EC093_PreSelection_SuperUsers su
			on cd.FanID = su.FanID
		Where PaymentMethodsAvailableID = 2
	
END


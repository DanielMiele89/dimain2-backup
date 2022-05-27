-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE ExcelQuery.ROCEFT_CardTypeDistribution 
	@StartDate Date
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Retrieve a PublisherList
	IF OBJECT_ID('tempdb..#Publisher') IS NOT NULL DROP TABLE #Publisher
	Select	PublisherID
			,PublisherName
	Into	#Publisher
	From	Warehouse.ExcelQuery.ROCEFT_Publishers
	Where	PublisherName <> 'R4G'

	CREATE CLUSTERED INDEX ix_PublisherID ON #Publisher(PublisherID)

	-- Retrieve all cards registered on any of the NFI schemes
	IF OBJECT_ID('tempdb..#CardList') IS NOT NULL DROP TABLE #CardList
	Select	distinct f.ID
			,f.CompositeID
			,f.ClubID as PublisherID
			,pub.PublisherName
			,p.PaymentCardID
			,pc.CardTypeID
			,pc.MaskedCardNumber
	Into	#CardList
	From	SLC_Report.dbo.Pan as P
	Join	SLC_Report.dbo.Fan as f ON f.CompositeID = p.CompositeID
	Join	#Publisher pub on pub.PublisherID = f.ClubID
	Join	PaymentCard pc on p.PaymentCardID = pc.ID
	Where   p.AdditionDate < DATEADD(dd, 1, @startdate) 
		and	(p.RemovalDate IS NULL OR p.RemovalDate > @StartDate)
		and (
				(      
					p.DuplicationDate IS NULL OR p.DuplicationDate > @StartDate
				)
			OR 
				(
					p.DuplicationDate <= @StartDate 
				AND EXISTS (	Select	1
								From	SLC_Report.dbo.Pan ps 
								Join	SLC_Report.dbo.Fan fs ON ps.CompositeID = fs.CompositeID
								Where	ps.PaymentCardID = p.PaymentCardID
									and ps.AdditionDate between p.AdditionDate and @StartDate
									and fs.ClubID = 141 -- P4L
							) 
				)
			)

	-- Perform a 'dumb' assignment of the AMEX/VISA/MasterCard Labelling
	IF OBJECT_ID('tempdb..#LabelledCards') IS NOT NULL DROP TABLE #LabelledCards
	Select	*
			,case
				when CardTypeID = 1 Then 'Credit'
				when CardTypeID = 2 Then 'Debit'
				else NULL
			 end as CreditOrDebit
			,case
				when MaskedCardNumber like '3%' then 'AMEX'
				when MaskedCardNumber like '4%' then 'VISA'
				when MaskedCardNumber like '5%' then 'Mastercard'
				else 'Other'
			 end as CardName
	Into	#LabelledCards
	From	#CardList

	CREATE CLUSTERED INDEX ix_CompositeID ON #LabelledCards(CompositeID)

	-- Find Topline Metrics (which will be needed in the join)
	IF OBJECT_ID('tempdb..#ToplineMetrics') IS NOT NULL DROP TABLE #ToplineMetrics
	Select	PublisherID
			,PublisherName
			,count(distinct CompositeID) as Cardholders
			,count(distinct PaymentCardID) as Cards
	Into	#ToplineMetrics
	From	#CardList
	Group By PublisherID
			,PublisherName

	-- Find those with more than a single card
	Select		a.PublisherID
				,a.PublisherName
				,a.CardName as FirstCard
				,b.CardName as SecondCard
				,tm.Cardholders as Pub_Cardholders
				,count(distinct a.CompositeID) as Cardholders
				,tm.Cards as Pub_Cards
				,count(distinct a.PaymentCardID) as Cards
	Into		Warehouse.ExcelQuery.ROCEFT_CardsMix
	From	(	Select	distinct PublisherID
						,PublisherName
						,CardName
						,PaymentCardID
						,CompositeID
				From #LabelledCards
			) a
	Join	(	Select	distinct PublisherID
						,PublisherName
						,CardName
						,PaymentCardID
						,CompositeID
				From #LabelledCards
			) b on a.compositeid = b.compositeid
	Join	#ToplineMetrics tm on a.PublisherName = tm.PublisherName
	Group by a.PublisherID
			,a.PublisherName
			,a.CardName
			,b.CardName
			,tm.Cardholders
			,tm.Cards
	Order by a.PublisherName
			,a.CardName
			,b.CardName

	--IF OBJECT_ID('Warehouse.ExcelQuery.ROCEFT_CardsMix') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.ROCEFT_CardsMix
	--CREATE TABLE Warehouse.ExcelQuery.ROCEFT_CardsMix
	--	(
	--		PublisherID int
	--		,PublisherName varchar(50)
	--		,FirstCard varchar(50)
	--		,SecondCard varchar(50)
	--		,Publisher_Cardholders int
	--		,Combo_Cardholders int
	--		,Publisher_Cards int
	--		,Combo_Cards int
	--	)

END

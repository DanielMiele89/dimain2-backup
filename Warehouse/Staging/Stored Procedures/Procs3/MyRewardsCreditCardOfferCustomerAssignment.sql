/*

	Date:			30th August 2017

	Author:			Zoe Taylor

	Purpose:		To select all credit card customers to be added to the credit card offers



*/

CREATE PROCEDURE Staging.MyRewardsCreditCardOfferCustomerAssignment (@RBS int, @Natwest int, @Start date, @Type bit)
AS 


Declare @RBSOffer int, @NatwestOffer int, @StartDate date, @RunType bit

Set @RbsOffer = @RBS
Set @NatwestOffer = @Natwest
Set @RunType = @Type
Set @StartDate = @Start


/******************************************************************		
		Checking offers 
******************************************************************/

If @RunType = 0 
Begin

		Select *
		from warehouse.relational.IronOffer
		where ironofferid in (@RBSOffer, @NatwestOffer)

End 


If @RunType = 1
Begin

		------------------------------------------------------------------------------------------
		--------------------------------------Select Customers------------------------------------
		------------------------------------------------------------------------------------------
		if object_id('tempdb..#OfferMemberAddition') is not null drop table #OfferMemberAddition
		Select	c.CompositeID,
				Case
					When ClubID = 132 then @NatwestOffer
					Else @RBSOffer
				End as IronOfferID,
				Cast(@StartDate as datetime) as StartDate,
				NULL as EndDate, --****No end date as details in collateral
				GetDate() as [Date],
				0 as IsControl
		Into #OfferMemberAddition
		From warehouse.Relational.Customer as c
		inner join Warehouse.Relational.CustomerPaymentMethodsAvailable as pma
			on c.FanID = pma.FanID and
				pma.EndDate is null and
				pma.PaymentMethodsAvailableID in (1,2)
		Where	c.CurrentlyActive = 1
		
		------------------------------------------------------------------------------------------
		----------------------------------Check clubs vs. offers----------------------------------
		------------------------------------------------------------------------------------------
		Select	'#OfferMemberAddition Counts' Description,
				IronOfferID,
				ClubID,
				Count(*) as [Rows],
				Count(Distinct FanID) as Customers
		From #OfferMemberAddition as oma
		inner join warehouse.relational.Customer as c
			on oma.CompositeID = c.CompositeID
		Group By IronOfferID,ClubID
		Order by ClubID

		------------------------------------------------------------------------------------------
		-------------------------------------Check Credit Cardholders-----------------------------
		------------------------------------------------------------------------------------------

		Select	'Credit Card Customer Check' Description, 
				b.IsCredit
				,Count(*)
		From #OfferMemberAddition as oma
		inner join warehouse.relational.customer as c
			on oma.CompositeID = c.CompositeID
		inner join SLC_Report.dbo.FanSFDDailyUploadData as b
			on c.fanid = b.fanid
		Group By b.IsCredit


		------------------------------------------------------------------------------------------
		---------------------------------Manually check customers are valid-----------------------
		------------------------------------------------------------------------------------------

		Select top (10) 'Natwest Offer' Description, c.FanID,c.Email,cAST(StartDate AS DATE) AS StartDate,EndDate,c.clubid from #OfferMemberAddition as oma
		inner join Warehouse.relational.customer as c
			on oma.CompositeID = c.CompositeID
		Where	ironofferid = @NatwestOffer and
				EmailStructureValid = 1
		Order by Newid()

		Select top (10) 'RBS Offer' Description, c.FanID,c.Email,cAST(StartDate AS DATE) AS StartDate,EndDate,c.clubid from #OfferMemberAddition as oma
		inner join Warehouse.relational.customer as c
			on oma.CompositeID = c.CompositeID
		Where	ironofferid = @RBSOffer and
				EmailStructureValid = 1
		Order by Newid()


		------------------------------------------------------------------------------------------
		------------------------------Add members to OfferMember Addition-------------------------
		------------------------------------------------------------------------------------------

		Insert into Warehouse.[iron].[OfferMemberAddition]
		Select * from #OfferMemberAddition


		Select 'Iron.OfferMemberAddition Counts' Description,IronOfferID,StartDate,EndDate, Count(*), Count(Distinct CompositeID) as Customers
		From Warehouse.[iron].[OfferMemberAddition]
		Where IronOfferID in (@RBSOffer,@NatwestOffer)
		Group by IronOfferID,StartDate,EndDate


		------------------------------------------------------------------------------------------
		------------------------------Add Offers to OfferProcesLog-------------------------
		------------------------------------------------------------------------------------------

		Insert into Warehouse.[iron].[OfferProcessLog]
		Select Distinct IronOfferID,
						0 as IsUpdate,
						0 as Processed,
						Null as ProcessedDate
		From #OfferMemberAddition


		Select * from warehouse.iron.offerprocesslog order by 1 desc

		------------------------------------------------------------------------------------------
		------------------------------Add Offers to PartnerOffers_Base----------------------------
		------------------------------------------------------------------------------------------

		Insert into warehouse.relational.PartnerOffers_Base
		Select	I.PartnerID,
				P.Name as PartnerName,
				IronOfferName as OfferName,
				IronOfferID as OfferID,
				'0%' as CashbackRateText,
				0.00 as CashbackRateNumeric,
				Clubs,
				Case
					When i.Clubs = 'NatWest' then 132
					Else 138
				End as ClubID,
				StartDate,
				EndDate,
				1 as AllSegments,
				NULL as HTMID,
				1 as CardType
		from warehouse.relational.IronOffer as i
		inner join SLC_Report..partner as p
			on i.PartnerID = p.ID
		Where IronOfferID in (@RBSOffer,@NatwestOffer)

		Select * from warehouse.relational.PartnerOffers_Base

		Order by OfferID Desc



		------------------------------------------------------------------------------------------
		--------------------------------------------Samples---------------------------------------
		------------------------------------------------------------------------------------------

		Select Top (10) 'RBS Sample Customers' Description,
						c.FanID,
						ClubID,
						Email
		From warehouse.iron.OfferMemberAddition as oma
		inner join warehouse.relational.customer as c
			on oma.compositeID = c.CompositeID
		Where	IronOfferID in (@RBSOffer) and
				c.EmailStructureValid = 1 and
				c.MarketableByEmail = 1
		Union All
		Select Top (10) 'Natwest Sample Customers' Description,
						c.FanID,
						ClubID,
						Email
		From warehouse.iron.OfferMemberAddition as oma
		inner join warehouse.relational.customer as c
			on oma.compositeID = c.CompositeID
		Where	IronOfferID in (@NatwestOffer) and
				c.EmailStructureValid = 1 and
				c.MarketableByEmail = 1

End
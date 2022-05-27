Create Procedure Staging.SSRS_R0199_LivePartnersByPublisher
as
Begin

	Select PartnerID
		 , PartnerName
		 , Coalesce([MyRewards],0) as [MyRewards]
		 , Coalesce([Quidco],0) as [Quidco]
		 , Coalesce([Karrot],0) as [Airtime]
		 , Coalesce([Next Jump],0) as [Next Jump]
		 , Coalesce([VAA Collinson Group],0) as [VAA - Collinson Group]
		 , Coalesce([British Airways Collinson Group],0) as [British Airways - Collinson Group]
		 , Coalesce([Gobsmack More Than],0) as [More Than - Gobsmack]
		 , Coalesce([Mustard Gobsmack],0) as [Mustard - Gobsmack]
		 , Coalesce([Affinion - Total Savings],0) as [Complete Savings - Affinion]
	From (Select Distinct 
	  			 Case
					When cl.Name Like '%MyRewards%' Then 'MyRewards'
					Else cl.Name
				 End as ClubName
	  		   , pa.ID as PartnerID
	  		   , pa.Name as PartnerName
			   , Convert(Int, 1) as LiveOffer
		  From SLC_Report..IronOffer iof
		  Inner join SLC_Report..Partner pa
	  		  on iof.PartnerID = pa.ID
		  Inner join SLC_Report..IronOfferClub ioc
	  		  on iof.ID = ioc.IronOfferID
		  Inner join SLC_Report..Club cl
	  		  on ioc.ClubID = cl.ID
		  Where (iof.EndDate Is Null Or iof.EndDate > GetDate())
		  And IsDefaultCollateral = 0
		  And IsAboveTheLine = 0
		  And IsSignedOff = 1
		  And pa.ID Not In (4642, 4497, 4648, 4498)	--	Credit Card Open Promotion, Credit Supermarket, Direct Debit- Household Bills 3, Spend 0.5%
		  And pa.Name Not Like '%AMEX'
		  And pa.Name Not Like '%AMEX)') [all]
	PIVOT (Sum(LiveOffer) For ClubName In ([Quidco], [MyRewards], [Karrot], [Next Jump], [VAA Collinson Group], [British Airways Collinson Group], [Gobsmack More Than], [Mustard Gobsmack], [Affinion - Total Savings])) as pvt

End

/********************************************************************************************
	Name: Staging.SSRS_R0181_FullSample_OfferSlotData
	Desc: Gets all offer information for SmartEmail sample customers in order to cross check 
			offer uploads
	Auth: Zoe Taylor

	Change History
			Initials Date
				Change Info
	
*********************************************************************************************/

CREATE PROCEDURE [Staging].[SSRS_R0181_FullSample_OfferSlotData]
--with Execute as Owner
As
Begin 


	/******************************************************************		
			Get all sample customer information 
	******************************************************************/

		If OBJECT_ID('tempdb..#t1') is not null drop table #t1
		Select * 
		Into #t1 
		From Warehouse.[SmartEmail].[VW_SmartEmailDailyData] as a
		Where email like 'Sampl%Rewardinsight.com'

	/******************************************************************		
			Get raw offer information per customer 
	******************************************************************/

		If OBJECT_ID('tempdb..#Offers') is not null drop table #Offers
		Select FanID,Email,Offer1,OFFER1STARTDATE,OFFER1ENDDATE,1 as Slot
		Into #Offers
		From #t1
		Union All
		Select FanID,Email,Offer2,OFFER2STARTDATE,OFFER2ENDDATE,2
		From #t1
		Union All
		Select FanID,Email,Offer3,OFFER3STARTDATE,OFFER3ENDDATE,3
		From #t1
		Union All
		Select FanID,Email,Offer4,OFFER4STARTDATE,OFFER4ENDDATE,4
		From #t1
		Union All
		Select FanID,Email,Offer5,OFFER5STARTDATE,OFFER5ENDDATE,5
		From #t1
		Union All
		Select FanID,Email,Offer6,OFFER6STARTDATE,OFFER6ENDDATE,6
		From #t1
		Union All
		Select FanID,Email,Offer7,OFFER7STARTDATE,OFFER7ENDDATE,7
		From #t1


	/******************************************************************		
			Link up to real customer information in order to split
			by brand 
	******************************************************************/

		Select	s.ID,
				o.EMAIL,
				c.ClubID,
				Case when ClubID = 132 then 
					Case
						When d.[CustomerSegment] is null then 'NWC'
						When d.[CustomerSegment] = 'V' then 'NWP'
						Else 'NWC'
					End 
				When ClubID = 138 Then 
					Case
						When d.[CustomerSegment] is null then 'RBSC'
						When d.[CustomerSegment] = 'V' then 'RBSP'
						Else 'RBSC'
					End 
				Else 'None' 
				End as ClubSegment,
				i.IronOfferID,
				i.IronOfferName,
				OFFER1STARTDATE,
				OFFER1ENDDATE,
				Slot,
				CASE
					When i.StartDate > GetDate() then 'New'
					Else 'Existing'
				End as [Offer Age],
				Case
					When DENSE_RANK() Over (Partition by i.IronOfferID 
											 Order by s.ID
													, Case
															When Slot = 7 then 0
															Else Slot
													  End Asc)= 1
					And i.StartDate > GetDate() then '1' 
					Else null
				End as OfferRankColour
		From #Offers as o
		inner join Warehouse.Relational.IronOffer as i
			on o.OFFER1 = i.IronOfferID
		inner join warehouse.SmartEmail.SampleCustomersList as s
			on o.FANID = s.FanID
		inner join warehouse.SmartEmail.SampleCustomerLinks as l
			on s.ID = l.SampleCustomerID
		inner join warehouse.relational.Customer as c
			on l.RealCustomerFanID = c.FanID
		Left Outer join warehouse.[Relational].[Customer_RBSGSegments] as d
			on c.FanID = d.FanID and
					d.EndDate is null
		Order by	s.ID,
					Case
						When Slot = 7 then 0
						Else Slot
					End Asc

End





CREATE PROCEDURE [Staging].[SSRS_R0178_CampaignSelectionSample_Display]
AS

BEGIN

/********************************************************************************************************************
Title: Campaign Selection - Sample Selection Display
Author: Stuart Barnley
Creation Date: 17 November 2017
Purpose: To display the sample data for the campaign, to be run from SSRS report
*********************************************************************************************************************/

Select * From (
Select	Distinct 
		s.ClientServicesRef,
		s.IronOfferID,
		s.IronOfferName,
		s.TopCashBackRate,
		Cast(s.StartDate as date) As StartDate,
		CASE
			When s.StartDate > GetDate() then 'New'
			Else 'Existing'
		End as [Offer Age],
		b.FanID,
		b.EmailAddress,
		Case 
			When s.ClubID = 132 then 'Natwest'
			Else case
			When s.ClubID = 138 then 'RBS'
			Else ''
		End End + ' - ' +
		Case
			When csm.CustomerSegment = 'V' then 'Private'
			Else 'Core'
		End as ClubSegment,
		a.[RowCount]
from Staging.R_0132_LionSendComponent_Sample as s
	Inner Join (Select CompositeID,Count(*) as [RowCount]
				from Staging.R_0132_LionSendComponent_Sample as s
				Group By CompositeID
				) as a
				on s.CompositeID = a.CompositeID
		inner join warehouse.relational.customer as c
	on s.compositeid = c.compositeid
inner join warehouse.relational.Customer_RBSGSegments as csm
	on c.FanID = csm.FanID and enddate is null
inner join warehouse.SmartEmail.SampleCustomerLinks as l
	on c.fanid = l.RealCustomerFanID
inner join warehouse.SmartEmail.SampleCustomersList as b
	on l.SampleCustomerID = b.ID
) as a
Order by ClubSegment,[RowCount]Desc,a.FanID,TopCashbackRate Desc

END
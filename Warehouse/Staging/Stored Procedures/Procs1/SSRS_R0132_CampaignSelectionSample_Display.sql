
CREATE PROCEDURE [Staging].[SSRS_R0132_CampaignSelectionSample_Display]
AS

BEGIN

/********************************************************************************************************************
Title: Campaign Selection - Sample Selection Display
Author: Zoe Taylor
Creation Date: 14 November 2016
Purpose: To display the sample data for the campaign, to be run from SSRS report "R0139_CampaignSelection_Display" 										
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
		s.CompositeID,
		s.Email,
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
) as a
Order by ClubSegment,[RowCount]Desc,a.CompositeID,TopCashbackRate Desc

END
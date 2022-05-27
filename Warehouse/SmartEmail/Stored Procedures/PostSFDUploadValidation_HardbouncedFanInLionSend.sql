
/**********************************************************************

	Author:		 Rory Francis
	Create date: 16 Oct 2018
	Description: Create list of customers that have been included in the Lion Send as they are marked as marketable
				 so are not included in segment counts on SFD as they have hardbounced but this has not carried over
				 to DIMAIN

	======================= Change Log =======================


***********************************************************************/


CREATE PROCEDURE [SmartEmail].[PostSFDUploadValidation_HardbouncedFanInLionSend] (@aLionSendID Int)

As
	Begin
		Set NoCount On;

		Declare @LionSendID Int = @aLionSendID

	/*******************************************************************************************************************************************
		1. Fetch customers included in the LionSend
	*******************************************************************************************************************************************/

		If Object_ID('tempdb..#LionSend') Is Not Null Drop Table #LionSend
		Select Distinct FanID
		Into #LionSend
		From SmartEmail.OfferSlotData
		Where LionSendID = @LionSendID
		Union
		Select Distinct FanID
		From SmartEmail.RedeemOfferSlotData
		Where LionSendID = @LionSendID

		CREATE CLUSTERED INDEX CIX_Fan ON #LionSend (FanID)


	/*******************************************************************************************************************************************
		2. Fetch customers max hardbounce date and match to their current email address
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Hardbounce') IS NOT NULL DROP TABLE #Hardbounce;
		WITH
		HardBounce AS (SELECT FanID
							, MAX(EventDateTime) AS HardBounceDate
						FROM [Relational].[EmailEvent] ee
						WHERE EXISTS (SELECT 1 FROM #LionSend ls WHERE ee.FanID = ls.FanID)
						GROUP BY FanID
						HAVING MAX(EventDateTime) = MAX(CASE WHEN EmailEventCodeID = 702 THEN EventDateTime END))

		SELECT hb.FanID
			 , hb.HardBounceDate
		INTO #Hardbounce
		FROM HardBounce hb
				
		CREATE CLUSTERED INDEX CIX_FanID ON #Hardbounce (FanID)


	/*******************************************************************************************************************************************
		3. Insert to permanent table with LionSendID included
	*******************************************************************************************************************************************/

		Insert into SmartEmail.PostSFDUploadValidation_HardbouncedFansIncInLionSend (LionSendID
																				   , FanID
																				   , Email
																				   , HBEventDateTime)
		Select @LionSendID as LionSendID
			 , hb.FanID
			 , Email
			 , HardBounceDate
		FROM #Hardbounce hb
		INNER JOIN [Staging].[Customer_EmailAddressChanges_20150101] eac
				ON hb.FanID = eac.FanID
		WHERE hb.HardBounceDate < eac.DateChanged

	End
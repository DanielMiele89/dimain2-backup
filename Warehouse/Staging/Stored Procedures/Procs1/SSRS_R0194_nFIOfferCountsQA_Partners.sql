/*
	
	Author:		Rory

	Date:		22nd November 2018

	Purpose:	To review the offer setup, namely cashback & spend stretch rules
				for existing offers
				
*/


CREATE Procedure [Staging].[SSRS_R0194_nFIOfferCountsQA_Partners] @WithErrors Int

As
Begin

	Select *
	From ##SSRS_R0194_nFIOfferCountsQA
	Where PotentialError_Partner In (@WithErrors, 1)

End
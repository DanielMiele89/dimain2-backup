-- =============================================
-- Author:		JEA
-- Create date: 24/04/2014
-- Description:	Retrieves customers changed from the ref table
-- for RBS Portal Incremental Load
-- =============================================
CREATE PROCEDURE [MI].[RBSPortal_CustomersChanged_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

	--NB: ANSI_NULLS OFF DOES NOT WORK IN THE JOIN CONDITION, SO WE HAVE TO TEST

	SELECT c.FanID
	FROM MI.RBSPortal_Customer_Check c
	LEFT OUTER JOIN MI.RBSPortal_Customer_Ref r
		ON c.FanID = r.FanID
		AND ((c.DOB IS NULL AND r.DOB IS NULL) OR c.DOB = r.DOB)
		AND c.ActivatedDate = r.ActivatedDate
		AND ((c.DeactivatedDate IS NULL AND r.DeactivatedDate IS NULL) OR c.DeactivatedDate = r.DeactivatedDate)
		AND ((c.OptedOutDate IS NULL AND r.OptedOutDate IS NULL) OR c.OptedOutDate = r.OptedOutDate)
		AND c.GenderID = r.GenderID
		AND ((c.AgeBandID IS NULL AND r.AgeBandID IS NULL) OR c.AgeBandID = r.AgeBandID)
		AND ((c.BankID IS NULL AND r.BankID IS NULL) OR c.BankID = r.BankID)
		AND ((c.RainbowID IS NULL AND r.RainbowID IS NULL) OR c.RainbowID = r.RainbowID)
		AND c.ChannelPreferenceID = r.ChannelPreferenceID
		AND c.ActivationMethodID = r.ActivationMethodID
		--AND ((c.JourneyStageID IS NULL AND r.JourneyStageID IS NULL) OR c.JourneyStageID = r.JourneyStageID)
		--AND c.ContactByEmail = r.ContactByEmail
		--AND c.ContactByPhone = r.ContactByPhone
		--AND c.ContactBySMS = r.ContactBySMS
		--AND c.ContactByPost = r.ContactByPost
		--AND ((c.IsLapsed IS NULL AND r.IsLapsed IS NULL) OR c.IsLapsed = r.IsLapsed)
		--AND c.JourneyStageDetailedID = r.JourneyStageDetailedID
		--AND c.EmailEngaged = r.EmailEngaged
		--AND c.Registered = r.Registered
	WHERE r.FanID IS NULL

END
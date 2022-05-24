-- =============================================
-- Author:		JEA
-- Create date: 18/08/2014
-- Description:	Retrieves activation figures, CB+ and credit card
-- =============================================
CREATE PROCEDURE [MI].[RBS_Activations_CreditCard_Daily_Fetch]

AS
BEGIN

	SET NOCOUNT ON;

	SELECT TOP 1 RunDate,
		ActivationOnlineRegisteredPrevDayNatWest,
		ActivationOnlineUnregisteredPrevDayNatWest,
		ActivationOfflinePrevDayNatWest,
		OptOutOnlinePrevDayNatWest,
		OptOutOfflinePrevDayNatWest,
		DeactivationPrevDayNatWest,
		ActivationOnlineRegisteredCumulNatWest,
		ActivationOnlineUnregisteredCumulNatWest,
		ActivationOfflineCumulNatWest,
		OptOutOnlineCumulNatWest,
		OptOutOfflineCumulNatWest,
		DeactivationCumulNatWest,
		EarnersMonthNatWest,
		EarnersCumulNatWest,
		ActivationOnlineRegisteredPrevDayRBS,
		ActivationOnlineUnregisteredPrevDayRBS,
		ActivationOfflinePrevDayRBS,
		OptOutOnlinePrevDayRBS,
		OptOutOfflinePrevDayRBS,
		DeactivationPrevDayRBS,
		ActivationOnlineRegisteredCumulRBS,
		ActivationOnlineUnregisteredCumulRBS,
		ActivationOfflineCumulRBS,
		OptOutOnlineCumulRBS,
		OptOutOfflineCumulRBS,
		DeactivationCumulRBS,
		EarnersMonthRBS,
		EarnersCumuRBS,
		CCActivationOnlineRegisteredPrevDayNatWest,
		CCActivationOnlineUnregisteredPrevDayNatWest,
		CCActivationOfflinePrevDayNatWest,
		CCAdditionOnlineRegisteredPrevDayNatWest,
		CCAdditionOnlineUnregisteredPrevDayNatWest,
		CCAdditionOfflinePrevDayNatWest,
		CCRemovalOnlinePrevDayNatWest,
		CCRemovalOfflinePrevDayNatWest,
		CCDeactivationPrevDayNatWest,
		CCActivationOnlineRegisteredCumulNatWest,
		CCActivationOnlineUnregisteredCumulNatWest,
		CCActivationOfflineCumulNatWest,
		CCAdditionOnlineRegisteredCumulNatWest,
		CCAdditionOnlineUnregisteredCumulNatWest,
		CCAdditionOfflineCumulNatWest,
		CCRemovalOnlineCumulNatWest,
		CCRemovalOfflineCumulNatWest,
		CCDeactivationCumulNatWest,
		CCActivationOnlineRegisteredPrevDayRBS,
		CCActivationOnlineUnregisteredPrevDayRBS,
		CCActivationOfflinePrevDayRBS,
		CCAdditionOnlineRegisteredPrevDayRBS,
		CCAdditionOnlineUnregisteredPrevDayRBS,
		CCAdditionOfflinePrevDayRBS,
		CCRemovalOnlinePrevDayRBS,
		CCRemovalOfflinePrevDayRBS,
		CCDeactivationPrevDayRBS,
		CCActivationOnlineRegisteredCumulRBS,
		CCActivationOnlineUnregisteredCumulRBS,
		CCActivationOfflineCumulRBS,
		CCAdditionOnlineRegisteredCumulRBS,
		CCAdditionOnlineUnregisteredCumulRBS,
		CCAdditionOfflineCumulRBS,
		CCRemovalOnlineCumulRBS,
		CCRemovalOfflineCumulRBS,
		CCDeactivationCumulRBS
	FROM MI.RBS_Activations_CreditCard_Daily
	ORDER BY RunDate DESC

END
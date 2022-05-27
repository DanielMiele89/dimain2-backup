-- =============================================
-- Author:		JEA
-- Create date: 30/09/2013
-- Description:	Updates CustomerActivationPeriod with an ActivationEnd date
-- =============================================
CREATE PROCEDURE [MI].[CustomerActivationPeriod_ActivationEnd_Update]
	(
		@FanID INT
		, @ActivationEnd DATE
		, @ActivationStatusID TINYINT
	)
AS
BEGIN

	SET NOCOUNT ON;

    UPDATE MI.CustomerActivationPeriod
	SET ActivationEnd = @ActivationEnd
	WHERE FanID = @FanID
	AND ActivationStart <= @ActivationEnd
	AND (ActivationEnd IS NULL OR ActivationEnd > @ActivationEnd)

	IF @ActivationStatusID = 2
	BEGIN
		UPDATE MI.CustomerActiveStatus SET OptedOutDate = @ActivationEnd
		WHERE FanID = @FanID
		AND (OptedOutDate IS NULL OR OptedOutDate > @ActivationEnd)
		AND ActivatedDate <= @ActivationEnd
	END
	ELSE
	BEGIN
		UPDATE MI.CustomerActiveStatus SET DeactivatedDate = @ActivationEnd
		WHERE FanID = @FanID
		AND (DeactivatedDate IS NULL OR DeactivatedDate > @ActivationEnd)
		AND ActivatedDate <= @ActivationEnd
	END
	
END

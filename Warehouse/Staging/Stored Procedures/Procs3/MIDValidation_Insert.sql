
CREATE PROCEDURE [Staging].[MIDValidation_Insert]
AS
	BEGIN

		DECLARE @ValidationID INT

		SELECT @ValidationID = MAX(COALESCE(ValidationID, 0)) + 1
		FROM (	SELECT MAX(ValidationID) AS ValidationID
				FROM [Staging].[MIDValidation_MIDs]
				UNION ALL
				SELECT MAX(ValidationID) AS ValidationID
				FROM [Staging].[MIDValidation_Details]) mv

		DELETE
		FROM [Staging].[MIDValidation_MIDs]
		WHERE ValidationID = @ValidationID

		DELETE
		FROM [Staging].[MIDValidation_Details]
		WHERE ValidationID = @ValidationID

		INSERT INTO [Staging].[MIDValidation_MIDs]
		SELECT	@ValidationID
			,	GETDATE()
			,	PartnerName
			,	BrandID
			,	MerchantID
			,	AddressLine1
			,	AddressLine2
			,	City
			,	Postcode
			,	County
			,	ContactPhone
			,	PartnerOutletReference
			,	Channel
			,	Notes
		FROM [Staging].[MIDValidation_MIDs_Import]

		INSERT INTO [Staging].[MIDValidation_Details]
		SELECT	@ValidationID
			,	GETDATE()
			,	REPLACE(ss.Item, ' ', '') AS PartnerID
			,	mv.BrandID
			,	mv.MIDListType
			,	mv.RetailerType
		FROM [Staging].[MIDValidation_Details_Import] mv
		CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (mv.PartnerID, ',') ss

	END

CREATE PROCEDURE [Staging].[MIDValidation_CleanUp]
AS
	BEGIN

	/*******************************************************************************************************************************************
		1. Remove all blank rows
	*******************************************************************************************************************************************/

		DELETE
		FROM [Staging].[MIDValidation_Import]
		WHERE MerchantID = ''
		OR MerchantID IN ('0', '#REF!')


	/*******************************************************************************************************************************************
		2. Update 0 value rows to be blank
	*******************************************************************************************************************************************/

		UPDATE [Staging].[MIDValidation_Import]
		SET Address1 = CASE WHEN Address1 IN ('0', '#REF!') THEN '' ELSE [dbo].[InitCap] (Address1) END
		  , Address2 = CASE WHEN Address2 IN ('0', '#REF!') THEN '' ELSE [dbo].[InitCap] (Address2) END
		  , City = CASE WHEN City IN ('0', '#REF!') THEN '' ELSE [dbo].[InitCap] (City) END
		  , Postcode = CASE WHEN Postcode IN ('0', '#REF!') THEN '' ELSE Postcode END
		  , County = CASE WHEN County IN ('0', '#REF!') THEN '' ELSE [dbo].[InitCap] (County) END
		  , Telephone = CASE WHEN Telephone IN ('0', '#REF!') THEN '' ELSE Telephone END
		  , PartnerOutletReference = CASE WHEN PartnerOutletReference IN ('0', '#REF!') THEN '' ELSE [dbo].[InitCap] (PartnerOutletReference) END
		  , Channel = CASE WHEN Channel IN ('0', '#REF!') THEN '' ELSE [dbo].[InitCap] (Channel) END

	END

	
	
	
	
	
	
	
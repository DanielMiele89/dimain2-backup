-- =============================================
-- Author:		<Shaun H>
-- Create date: <19/06/2017>
-- Description:	<Tool Export - Cards Mix (AMEX, Mastercard, VISA)>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_CardsMix_Fetch]
AS
BEGIN
	SET NOCOUNT ON;

	SELECT  PublisherID
			,PublisherName
			,CardName
			,Proportion_Cardholders
			,Proportion_Cards
	FROM	Warehouse.ExcelQuery.ROCEFT_CardsMix

END

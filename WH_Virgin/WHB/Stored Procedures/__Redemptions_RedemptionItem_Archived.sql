/*
-- REPLACEs this bunch of stored procedures:
EXEC WHB.Redemptions_RedemptionItem

*/
CREATE PROCEDURE [WHB].[__Redemptions_RedemptionItem_Archived]

AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);
	DECLARE @msg VARCHAR(200), @RowsAffected INT;


	EXEC [Monitor].[ProcessLog_Insert] 'Redemptions_RedemptionItem', 'Started'

	BEGIN TRY

-------------------------------------------------------------------------------
--EXEC WHB.Redemptions_RedemptionItem_V1_13 ###################################
-------------------------------------------------------------------------------

	--Insert Suggested Redemptions in RedemptionItem Table------------------
	/*This section is used to add the new redemptions that have been used by CashBack customers to
	  the redemptions table with the suggested Redemption types. The Type identification will need to 
	  be updated in line with the checking phase
	*/
If Object_ID('tempdb..#RedeemItems') Is Not Null Drop Table #RedeemItems
select
	r.ID as RedeemID,
	Case
	When r.ID in (7191,7192) then 'Trade Up'
	When r.Privatedescription like '%Donation to%' Then 'Charity'
	When r.Privatedescription like '%Donate%' Then 'Charity'
	When r.Privatedescription like '%gift card % CashbackPlus Rewards%' Then 'Trade Up'
	When r.Privatedescription like '%gift Code %' Then 'Trade Up'
	When r.Privatedescription like '%tickets % CashbackPlus Rewards%' Then 'Trade Up'
	When r.Privatedescription like 'Cash to bank account' Then 'Cash'
	When r.Privatedescription like '%RBS Current Account%' Then 'Cash'
	When r.Privatedescription like '%Pay towards your Cashback Plus Credit Card%' then 'Cash'
	When r.Privatedescription like '%for £_ Rewards%' then 'Trade Up'
	When r.Privatedescription like '%for £__ Rewards%' then 'Trade Up'
	When r.Privatedescription like '%Caff%Nero%' then 'Trade Up'
	End as RedeemType,
	r.Privatedescription,
	Cast(Null as int) as PartnerID,
	Cast(Null as [varchar](100)) as [PartnerName],
	Cast(Null as [int]) as [TradeUp_WithValue],
	Cast(Null as [smallmoney]) as [TradeUp_ClubcashRequired],
	Cast(Null as [smallmoney]) as [TradeUp_Value],
	Cast(Null as Bit) as [Status]
Into #RedeemItems
from  Derived.Customer c
INNER JOIN slc_report.dbo.Trans t 
	on t.FanID = c.FanID
INNER JOIN slc_report.dbo.Redeem r 
	on r.id = t.ItemID
INNER JOIN slc_report.dbo.RedeemAction ra 
	on t.ID = ra.transid and ra.Status = 1     
LEFT JOIN Staging.RedemptionItem as ri 
	on t.itemid = ri.redeemid
where	t.TypeID=3 
	and ri.redeemid is null
group by r.Privatedescription, r.ID 
	
	

--Deal with Problem redemption items--------------------------------
UPDATE ri
SET RedeemType = 'Trade Up',
	TradeUP_WithValue = 1,
	TradeUp_ClubcashRequired = r.TradeUp_ClubcashRequired,
	TradeUp_Value = r.TradeUp_Value
FROM #RedeemItems as ri
INNER JOIN Derived.RedemptionItem_TradeUpValue  as r
	on ri.RedeemID = r.RedeemID


--Deal with Problem redemption items--------------------------------
/* ChrisM note - this doesn't work, it sets every row of #RedeemItems to Cafe Nero
But it's corrected in the next statement!!
UPDATE #RedeemItems
SET PartnerID = a.PartnerID,
	PartnerName = p.PartnerName
FROM (
	Select Case
		When RedeemType = 'Trade Up' and PrivateDescription like '%digital magazines for %Rewards%' then 1000000
		When RedeemType = 'Trade Up' and replace(replace(PrivateDescription,' ',''),'&','') like '%CurrysPCWorld%' then 4001
		When PrivateDescription like '%Caff_ Nero%' then 4319
		When RedeemType = 'Trade Up' Then P.PartnerID
		Else NULL
		End as PartnerID,
		r.RedeemID
	From #RedeemItems as r
	left join Derived.Partner as p
		on	r.PrivateDescription like '%'+p.partnername+'%' 
		and r.PrivateDescription not like '%Currys%' 
		and r.PrivateDescription not like '%PC World%'
) as a
INNER JOIN Derived.Partner as p
	on a.PartnerID = p.PartnerID
*/

UPDATE ri
SET		PartnerID = p.PartnerID,
		PartnerName = p.PartnerName
FROM #RedeemItems as ri
INNER JOIN Derived.RedemptionItem_TradeUpValue as t
	on	ri.RedeemID = t.RedeemID
INNER JOIN Derived.partner as p
	on  t.PartnerID = p.PartnerID
WHERE	ri.PartnerID is null and
		t.partnerid is not null

--Create Relational.RedemptionItem lookup Table-------------------------
TRUNCATE TABLE Derived.RedemptionItem
INSERT INTO Derived.RedemptionItem
SELECT RedeemID
		, RedeemType
		, PrivateDescription
		, Status
FROM #RedeemItems ri



















			EXEC Monitor.ProcessLog_Insert 'Redemptions_RedemptionItem', 'Finished'

			RETURN 0; -- normal exit here

	END TRY
	BEGIN CATCH		
		
		-- Grab the error details
			SELECT  
				@ERROR_NUMBER = ERROR_NUMBER(), 
				@ERROR_SEVERITY = ERROR_SEVERITY(), 
				@ERROR_STATE = ERROR_STATE(), 
				@ERROR_PROCEDURE = ERROR_PROCEDURE(),  
				@ERROR_LINE = ERROR_LINE(),   
				@ERROR_MESSAGE = ERROR_MESSAGE();
			SET @ERROR_PROCEDURE = ISNULL(@ERROR_PROCEDURE, OBJECT_NAME(@@PROCID))

			IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			
		-- Insert the error into the ErrorLog
			INSERT INTO Staging.ErrorLog (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
			VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

		-- Regenerate an error to return to caller
			SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
			RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

		-- Return a failure
			RETURN -1;

	END CATCH

	RETURN 0; -- should never run

END
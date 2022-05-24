
CREATE PROCEDURE [Staging].[DailyCashbackAwarded_SendEmail]
AS
BEGIN

		/*******************************************************************************************************************************************
			1.	Store values into parameters
		*******************************************************************************************************************************************/
	
			DECLARE @Today DATE = GETDATE()
				,	@CashbackAwarded DECIMAL(32, 2)
				,	@CashbackAwardedSinceKillianJoined DECIMAL(32, 2)
				,	@PreviousCashbackAwarded DECIMAL(32, 2)
				,	@IncreaseInCashbackAwarded DECIMAL(32, 2)
	
				,	@CashbackAwardedVar VARCHAR(25)
				,	@CashbackAwardedSinceKillianJoinedVar VARCHAR(25)
				,	@CashbackAwardedSubjectLineVar VARCHAR(50)
				,	@IncreaseInCashbackAwardedVar VARCHAR(25)
	
	
			SELECT	@CashbackAwarded = CashbackAwarded
				,	@PreviousCashbackAwarded = PreviousCashbackAwarded
				,	@IncreaseInCashbackAwarded = IncreaseInCashbackAwarded
				,	@CashbackAwardedSinceKillianJoined = CashbackAwardedSinceKillianJoined
			FROM (	SELECT	 dca.Date
						,	 dca.CashbackAwardedSinceKillianJoined
						,	 dca.CashbackAwarded
						,	 PreviousCashbackAwarded = LAG(dca.CashbackAwarded) OVER (ORDER BY dca.Date) 
						,	 IncreaseInCashbackAwarded = dca.CashbackAwarded - LAG(dca.CashbackAwarded) OVER (ORDER BY dca.Date)
					FROM (	SELECT	dca.Date
								,	SUM(dca.CashbackAwarded) AS CashbackAwarded
								,	SUM(dca.CashbackAwardedSinceKilian) AS CashbackAwardedSinceKillianJoined
							FROM [Warehouse].[Staging].[DailyCashbackAwarded] dca
							GROUP BY dca.Date) dca) dca
			WHERE dca.Date = @Today

			SELECT	@CashbackAwardedVar = '£' + CONVERT(VARCHAR, CONVERT(MONEY, @CashbackAwarded), 1)
				,	@IncreaseInCashbackAwardedVar = '£' + CONVERT(VARCHAR, CONVERT(MONEY, @IncreaseInCashbackAwarded), 1)
				,	@CashbackAwardedSinceKillianJoinedVar = '£' + CONVERT(VARCHAR, CONVERT(MONEY, @CashbackAwardedSinceKillianJoined), 1)

			SELECT	@CashbackAwardedSubjectLineVar =  'Total Cashback Awarded - ' + REPLACE(LEFT(@CashbackAwardedVar, 6), ',', '.') + ' billion'

			--SELECT	@Today
			--	,	@CashbackAwarded
			--	,	@PreviousCashbackAwarded
			--	,	@IncreaseInCashbackAwarded

			--	,	@CashbackAwardedVar
			--	,	@CashbackAwardedSubjectLineVar
			--	,	@IncreaseInCashbackAwardedVar

		/*******************************************************************************************************************************************
			2. Declare User Variables & set initial email text & HTML style
		*******************************************************************************************************************************************/

			/***********************************************************************************************************************
				2.1. Declare User Variables
			***********************************************************************************************************************/

				Declare @Style VARCHAR(MAX)
					  , @Message VARCHAR(MAX)
					  , @Table VARCHAR(MAX)
					  , @Table2 VARCHAR(MAX)
					  , @Regards VARCHAR(MAX)
					  , @BodyEmail VARCHAR(MAX)
					
				Declare  @MessageKillian VARCHAR(MAX)
					  , @BodyEmailKillian VARCHAR(MAX)

			/***********************************************************************************************************************
				2.2. Set email HTML style
			***********************************************************************************************************************/

				SET @Style = 
				'<style>
					table {border-collapse: collapse;}

					p {font-family: Calibri;}
	
					th {padding: 10px;}
	
					table, td {padding: 0 10 0 10;}
	
					table, td, th {border: 1px solid black;
								   font-family: Calibri;}
				</style>'
			  

			/***********************************************************************************************************************
				2.3. Set opening message and sign offer
			***********************************************************************************************************************/

				-- Normal Messages, # Replaced with customer Count
				SET @Message = 'Hi all,' + '<br>' + '<br>' + 'As of yesterday, the Total Cashback Awarded is ##.' + '<br>' + '<br>' + 'This is up # from the previous weekday.' + '<br>'

				
				SET @Message = REPLACE(@Message, '##', @CashbackAwardedVar)
				SET @Message = REPLACE(@Message, '#', @IncreaseInCashbackAwardedVar)

				SET @MessageKillian = @Message + '<br>' + '# of this has been awarded since 3rd November 2021.' + '<br>'
				SET @MessageKillian = REPLACE (@MessageKillian, '#', @CashbackAwardedSinceKillianJoinedVar)
				Set @Regards = '<br>' + 'Regards,' + '<br>' + 'Data Operations'

		/*******************************************************************************************************************************************
			3. Combine variables to form email body
		*******************************************************************************************************************************************/

			SET @BodyEmail = @Style + @Message + @Regards
			SET @BodyEmailKillian = @Style + @MessageKillian + @Regards


		/*******************************************************************************************************************************************
			5. Send email
		*******************************************************************************************************************************************/

IF @@SERVERNAME = 'DIMAIN2' BEGIN

	EXEC msdb..sp_send_dbmail 
		@profile_name = 'Administrator',
		@recipients= 'Gavin Dein <gavin.dein@rewardinsight.com>; Anna-Louise Edwards <anna-louise.edwards@rewardinsight.com>; John Mills <john.mills@rewardinsight.com>; Junior Nelson <Junior.Nelson@rewardinsight.com>; Kate Sherratt <kate.sherratt@rewardinsight.com>; Mark Murray <Mark.Murray@rewardinsight.com>; Piers Sanders <Piers.sanders@rewardinsight.com>; Prakash Kelshiker <Prakash.Kelshiker@rewardinsight.com>; Sam Sprekos <sam.sprekos@rewardinsight.com>; Thomas Lewis <tom.lewis@rewardinsight.com> Lewis Young <lewis.young@rewardinsight.com>; Tanya de Sousa-Grimaldi <Tanya.de.Sousa-Grimaldi@rewardinsight.com>; Tracy Goncalves <tracy.goncalves@rewardinsight.com>; Peter West <peter.west@rewardinsight.com>; Tracy Webb <tracy.webb@rewardinsight.com>; Dave Cauldwell <dave.cauldwell@rewardinsight.com>; DI Process Checkers <DIProcessCheckers@rewardinsight.com>',
	--	@recipients= 'DI Process Checkers <DIProcessCheckers@rewardinsight.com>',
	--	@recipients= 'Rory Francis <Rory.Francis@rewardinsight.com>',
		@subject = @CashbackAwardedSubjectLineVar,
		@body= @BodyEmail,
		@body_format = 'HTML', 
		@importance = 'HIGH'

	EXEC msdb..sp_send_dbmail 
		@profile_name = 'Administrator',
		@recipients= 'Killian O’Rawe <killian.orawe@rewardinsight.com>; DI Process Checkers <DIProcessCheckers@rewardinsight.com>',
	--	@recipients= 'DI Process Checkers <DIProcessCheckers@rewardinsight.com>',
	--	@recipients= 'Rory Francis <Rory.Francis@rewardinsight.com>',
		@subject = @CashbackAwardedSubjectLineVar,
		@body= @BodyEmailKillian,
		@body_format = 'HTML', 
		@importance = 'HIGH'

END

END
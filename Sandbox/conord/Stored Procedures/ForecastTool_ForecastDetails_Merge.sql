
/******************************************************************************
Author: Sam Weber
Created: 08/11/2021
Purpose: 
	- Take the holding table into the actual table
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [conord].[ForecastTool_ForecastDetails_Merge]
--WITH EXECUTE AS 'Rory'
AS
	BEGIN

			MERGE [Sandbox].[ConorD].[ForecastingBudgetTracking] target			-- Destination table
			USING [Sandbox].[ConorD].[ForecastingBudgetTracking_Import] source	-- Source table
			ON target.[PublisherID] = source.[PublisherID]				-- Match criteria
			AND target.[BrandID] = source.[BrandID]						-- Match criteria
			AND target.[RetailerName] = source.[RetailerName]			-- Match criteria
			AND target.[PublisherName] = source.[PublisherName]			-- Match criteria
			AND target.[Segment] = source.[Segment]						-- Match criteria
			AND target.[Above] = source.[Above]							-- Match criteria
			AND target.[SpendStretch] = source.[SpendStretch]			-- Match criteria
			AND target.[Below] = source.[Below]							-- Match criteria
			AND target.[Bounty] = source.[Bounty]						-- Match criteria
			AND target.[OfferType] = source.[OfferType]					-- Match criteria
			AND target.[Spend] = source.[Spend]							-- Match criteria
			AND target.[Transactions] = source.[Transactions]			-- Match criteria
			AND target.[Customers] = source.[Customers]					-- Match criteria
			AND target.[Investment] = source.[Investment]				-- Match criteria
			AND target.[CycleStartDate] = source.[CycleStartDate]		-- Match criteria
			AND target.[CycleEndDate] = source.[CycleEndDate]			-- Match criteria
			AND target.[HalfCycleStart] = source.[HalfCycleStart]		-- Match criteria
			AND target.[HalfCycleEnd] = source.[HalfCycleEnd]	
			AND target.[ForecastID] = source.[ForecastID]-- Match criteria

			/*WHEN MATCHED 
			THEN UPDATE SET	 
			 target.[PublisherID] = source.[PublisherID]		,
			 target.[BrandID] = source.[BrandID]				,			
			 target.[RetailerName] = source.[RetailerName]		,	
			 target.[PublisherName] = source.[PublisherName]	,		
			 target.[Segment] = source.[Segment]				,	
			 target.[Above] = source.[Above]					,	
			 target.[SpendStretch] = source.[SpendStretch]		,	
			 target.[Below] = source.[Below]					,	
			 target.[Bounty] = source.[Bounty]					,
			 target.[OfferType] = source.[OfferType]			,
			 target.[Spend] = source.[Spend]					,	
			 target.[Transactions] = source.[Transactions]		,	
			 target.[Customers] = source.[Customers]			,
			 target.[Investment] = source.[Investment]			,
			 target.[CycleStartDate] = source.[CycleStartDate]	,
			 target.[CycleEndDate] = source.[CycleEndDate]		,
			 target.[HalfCycleStart] = source.[HalfCycleStart]	,
			 target.[HalfCycleEnd] = source.[HalfCycleEnd]	*/		
						
					
				WHEN NOT MATCHED BY TARGET								-- If not matched, add new rows
				THEN INSERT (
			 [PublisherID]						,
			 [BrandID]							,
			 [RetailerName]						,
			 [PublisherName]					,
			 [Segment]							,	
			 [Above]							,
			 [SpendStretch]						,
			 [Below]							,
			 [Bounty]							,
			 [OfferType]						,
			 [Spend]							,
			 [Transactions]						,
			 [Customers]						,
			 [Investment]						,
			 [CycleStartDate]					,
			 [CycleEndDate]						,
			 [HalfCycleStart]					,
			 [HalfCycleEnd]						,
			 [ForecastID]
			 )
					VALUES (
			 source.[PublisherID]				,
			 source.[BrandID]					,
			 source.[RetailerName]				,
			 source.[PublisherName]				,
			 source.[Segment]					,	
			 source.[Above]						,
			 source.[SpendStretch]				,
			 source.[Below]						,
			 source.[Bounty]					,
			 source.[OfferType]					,
			 source.[Spend]						,
			 source.[Transactions]				,
			 source.[Customers]					,
			 source.[Investment]				,
			 source.[CycleStartDate]			,
			 source.[CycleEndDate]				,
			 source.[HalfCycleStart]			,
			 source.[HalfCycleEnd]				,				
			 source.[ForecastID]
			 );

			 delete from ConorD.ForecastingBudgetTracking where PublisherID = '';

	END



CREATE PROCEDURE [Selections].[MOR158_PreSelection_sProc_Nursery]
AS
BEGIN


--- NURSERY OFFER ---
IF OBJECT_ID('tempdb..#FB3') IS NOT NULL DROP TABLE #FB3
SELECT	CINID ,FanID
INTO	#FB3
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
--AND FANID NOT IN (SELECT FANID FROM [InsightArchive].[MorrisonsReward_MatchedCustomers_20190304])		--NOT A MORECARD OWNER--


IF OBJECT_ID('tempdb..#Responders') IS NOT NULL DROP TABLE #Responders			
SELECT   F.CINID
INTO	#Responders
FROM	#FB3 F
JOIN	Relational.PartnerTrans PT on Pt.FanID = F.FanID
WHERE	PT.PartnerID = 4263
		AND TransactionDate >= '2021-12-30'
		AND TransactionAmount > 0
		AND PT.IronOfferID IN (25076)						
CREATE CLUSTERED INDEX cix_CINID ON #Responders(CINID)


IF OBJECT_ID('Sandbox.rukank.Morrisons_Nursery_Acquire_03052022') IS NOT NULL DROP TABLE Sandbox.rukank.Morrisons_Nursery_Acquire_03052022		
SELECT	F.CINID																														
INTO	Sandbox.rukank.Morrisons_Nursery_Acquire_03052022
FROM	#Responders F
WHERE	CINID NOT IN (SELECT CINID FROM Sandbox.rukank.Morrisons_Aldi_Lidl_03052022)															
		AND CINID NOT IN (SELECT CINID FROM					
												( SELECT CINID  FROM	Sandbox.rukank.Morrisons_Medium_SoW_ATV_0_15_03052022
												  UNION
												  SELECT CINID  FROM	Sandbox.rukank.Morrisons_Medium_SoW_ATV_15_35_03052022
												  UNION
												  SELECT CINID  FROM	Sandbox.rukank.Morrisons_Medium_SoW_ATV_35_03052022
												 ) A
								)
GROUP BY F.CINID

					
	IF OBJECT_ID('[Warehouse].[Selections].[MOR158_PreSelection_Nursery]') IS NOT NULL DROP TABLE [Warehouse].[Selections].MOR158_PreSelection_Nursery
	Select FanID
	Into [Warehouse].[Selections].MOR158_PreSelection_Nursery
	FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
	WHERE PartnerID = 4263
	AND EndDate IS NULL
	AND ShopperSegmentTypeID IN (9)
	AND EXISTS (    SELECT 1
					FROM #FB3 fb
					INNER JOIN Sandbox.rukank.Morrisons_Nursery_Acquire_03052022 sb
						ON fb.CINID = sb.CINID
					WHERE sg.FanID = fb.FanID)


END
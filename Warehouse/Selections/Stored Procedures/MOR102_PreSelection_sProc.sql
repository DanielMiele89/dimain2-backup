-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-08-18>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.MOR102_PreSelection_sProcASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID ,FanID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
AND		(PostalSector IN ('CT16 9','TN25 5','TN23 3','TN24 0','TN23 1','TN23 5','RH17 7','RH18 5','RH19 4','RH19 3','TN7 4','TN27 0','TN23 4','TN23 6','TN23 7','TN24 8','TN24 9','TN26 1'
						 ,'TN25 4','CT4 7','CT4 5','CT1 3','CT2 9','CT4 8','ME13 8','ME13 7','ME13 9','CT5 3','CT5 1','CT5 4','ME12 4','ME13 0','TN27 9','ME17 2','ME9 0','ME9 9','ME12 3'
						 ,'ME10 3','ME17 1','ME17 3','TN12 0','ME17 4','TN17 1','TN12 7','TN12 9','TN12 8','ME15 0','ME16 8','ME15 9','ME14 3','ME10 1','ME9 8','ME10 4','ME10 2','ME10 5'
						 ,'ME9 7','ME14 4','ME15 8','ME15 7','ME18 6','ME18 5','TN12 6','TN2 4','TN1 2','TN3 9','TN1 1','TN2 3','TN2 5','TN4 8','TN6 1','TN8 5','TN8 7','TN14 6','TN4 0'
						 ,'TN4 9','TN11 0','TN12 5','ME16 9','ME14 5','ME15 6','ME14 1','ME14 2','ME14 9','ME16 0','ME5 9','ME7 3','ME8 0','ME8 8','ME8 9','ME5 8','ME19 6','ME19 4'
						 ,'TN10 4','TN9 2','TN3 0','TN11 9','TN11 8','TN13 2','TN16 1','TN8 6','RH7 6','RH8 9','RH8 0','TN16 2','TN14 7','TN13 1','TN10 3','TN9 1','TN15 8','ME19 5'
						 ,'ME20 6','ME1 3','ME5 0','ME5 7','ME8 6','ME8 7','ME3 0','ME11 5','ME12 2','ME12 1','ME3 9','ME7 2','ME7 4','ME4 4','ME20 7','ME6 9','TN15 9','TN15 0','TN13 3'
						 ,'TN14 5','DA4 0','TN15 6','DA13 0','ME6 5','ME1 2','ME7 5','ME4 3','ME4 5','ME1 1','ME2 4','ME4 6','ME7 1','ME1 9','ME2 1','DA12 3','ME2 3','ME2 2','ME3 8'
						 ,'ME3 7','DA12 2','DA13 9','DA3 7','DA3 8','BR6 7','BR6 6','BR8 8','BR5 4','DA14 5','BR8 7','DA4 9','TN15 7','DA2 8','DA10 0','DA11 7','DA12 4','DA12 5'
						 ,'DA11 8','DA2 6','DA1 9','DA2 7','DA1 1','DA1 3','DA1 2','DA1 5','DA11 9','DA12 1','DA11 0','DA9 9','DA8 2','BR6 9','TN16 3','CR6 9','CR0 9','CR0 0','BR2 6'
						 ,'BR6 0','DA5 3','DA1 4','DA8 3','DA6 8','BR6 8','BR2 8','BR5 1','BR7 6','BR5 3','BR5 2','DA14 6','DA14 4','DA5 2','DA5 1','DA7 9','DA7 5','DA7 4','DA6 7'
						 )
OR		PostalSector IN ('DA7 6','DA8 1','DA15 7','BR1 2','BR2 9','BR4 9','BR2 7','BR4 0','BR3 6','BR2 0','BR1 3','BR1 9','BR1 1','SE12 0','BR1 4','BR1 5','SE6 1','SE12 9','SE9 3'
						 ,'DA16 1','DA17 6','DA17 5','SE9 2','SE9 4','SE3 9','SE12 8','BR7 5','DA16 2','DA15 8','DA15 9','DA18 4','DA16 3','SE9 1','SE9 5','SE3 8','SE18 4','SE18 2'
						 ,'SE2 0','SE18 3','SE9 6','SE7 7','SE13 6','SE13 5','SE3 0','SE10 8','SE10 9','SE3 7','SE7 8','SE18 1','SE28 8','SE2 9','SE18 7','SE18 6','SE18 5','SE18 9'
						 ,'SE28 0','SE10 0','BN6 8','BN6 9','BN45 7','RH15 0','RH15 9','RH15 8','RH16 4','RH16 1','RH16 3','RH16 2','RH16 9','BN5 9','BN44 3','RH20 3','RH13 8'
						 ,'RH17 5','RH17 6','RH19 1','RH10 4','RH10 5','RH11 9','RH11 6','RH13 6','RH14 0','RH14 9','RH13 9','RH13 0','RH12 1','RH12 5','RH13 5','RH12 4','RH10 7'
						 ,'RH19 2','RH9 8','RH10 6','RH11 0','RH11 7','RH10 1','RH10 3','RH6 9','RH1 5','RH10 9','RH11 8','RH12 2','RH12 3','RH5 5','GU6 7','GU6 8','GU8 4','GU5 0'
						 ,'GU5 9','RH5 6','RH5 4','RH6 0','RH10 8','RH6 7','RH6 8','RH2 8','RH2 7','RH1 6','RH1 4','CR3 5','CR3 7','CR3 6','CR3 0','CR8 5','RH1 1','RH2 0','RH3 7'
						 ,'KT20 7','RH2 9','RH1 2','RH1 3','CR2 9','CR2 8','CR9 0','CR0 8','CR8 1','CR5 1','KT20 6','CR5 3','CR8 4','CR2 0','CR8 2','CR2 6','CR0 5','CR9 3','CR5 2'
						 ,'SM7 2','SM7 1','KT20 5','KT17 3','KT17 4','KT18 6','KT22 8','RH4 2','RH4 1','RH4 3','RH4 9','KT22 7','KT23 4','KT24 5','KT23 3','KT21 2','KT18 5','SM7 3'
						 ,'CR8 3','SM6 0','SM6 9','CR2 7','CR9 5','SM5 4','SM2 7','KT18 7','KT22 9','KT21 1','SM1 4','SM5 3','CR0 1','CR9 7','BR3 3','BR3 5','BR3 4','CR0 7','CR9 1'
						 ,'SM6 8','SM2 6','SM2 5','SM6 7','CR9 4','CR0 3','CR0 6','CR9 6','CR0 2','CR7 6','CR0 4','CR7 7','CR9 2','SE25 6','SE20 7','BR3 1','SE25 4','CR7 8','SW16 4'
						 ,'CR4 1','SM5 2','CR4 2','SW12 9','SW16 2','SE19 2','SE25 5','SE19 3','SE19 1','SE20 8','SE6 3','SE23 2','SE26 4','SE26 5','SE6 4','SE26 6','SE21 7','SW16 3'
						 ,'SW16 5','SW16 1','SW17 6','SM4 9','SW17 8','SW17 7','SW17 9','SW11 6','SW12 0','SW16 6','SE27 0','SE22 0','SE6 2','SE13 7','SE23 3','SE27 9','SW2 1','SW12 8'
						 ,'SW11 1','SW2 4','SE21 8','SE23 1','SE4 2','SE14 6','SE4 1','SE15 3','SE22 8','SE24 9','SW2 3','SW2 5','SW4 7','SW4 0','SW4 8','SW2 2','SE22 9','SE8 4','SE8 3'
						 ,'SE8 5','SE14 5','SE15 4','SE15 5','SE5 9','SE24 0','SW9 8','SE5 0','SE15 1','SE15 2','SE16 2','SE16 7','SE16 5','SE15 6','SE17 2','SW9 7','SW4 6','SW4 9'
						 ,'SW8 2','SE11 4','SE11 5','SE17 3','SE5 7','SE1 3','SE16 3','SE5 8','SW8 4','SW11 4','SE17 1','SE16 4','SE1 5','SE1 2','SE1 4','SE1 6','SW8 3','SW11 2','SW11 3'
						 ,'SW9 9','SW9 0','SW11 5','SW9 6','SE1 9','SW8 1','SW8 5','SE11 6','SE1 8','SE1 7','SE1 1','SE1 0','TN23 9','ME10 9','DA12 9','BN99 8','RH12 9','RH2 2','SM1 9'
						 ,'CR9 8','SE6 9','SE16 6','SE5 5'
						 )
		)
CREATE CLUSTERED INDEX IX_CINID ON #FB(CINID)


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
INTO #CC
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (312)								-- Ocado


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
INTO #Trans
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
		AND	TranDate >= DATEADD(MONTH,-12,GETDATE())
GROUP BY F.CINID



IF OBJECT_ID('Sandbox.RukanK.Morrisons_ErithCFC_CompSteal27072021') IS NOT NULL DROP TABLE Sandbox.RukanK.Morrisons_ErithCFC_CompSteal27072021
SELECT	CINID
INTO	Sandbox.RukanK.Morrisons_ErithCFC_CompSteal27072021
FROM	#Trans
If Object_ID('Warehouse.Selections.MOR102_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR102_PreSelectionSelect FanIDInto Warehouse.Selections.MOR102_PreSelectionFROM SANDBOX.RUKANK.MORRISONS_ERITHCFC_COMPSTEAL27072021 sINNER JOIN #FB fb	ON s.CINID = fb.CINIDEND